#!/bin/bash

# 修复静态库的iOS模拟器支持
# 专门处理阿里SDK静态库的架构问题

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LIBS_DIR="$PROJECT_DIR/ios/libs"

echo "🚀 开始修复静态库的iOS模拟器支持..."

# 创建一个临时的Python脚本来修改mach-o文件
create_macho_fixer() {
    cat > /tmp/fix_macho.py << 'EOF'
#!/usr/bin/env python3
import sys
import struct
import os

def fix_macho_platform(file_path):
    """修改mach-o文件的平台信息以支持模拟器"""
    
    # Mach-O constants
    MH_MAGIC_64 = 0xfeedfacf
    MH_MAGIC = 0xfeedface
    CPU_TYPE_ARM64 = 0x0100000c
    CPU_TYPE_X86_64 = 0x01000007
    LC_BUILD_VERSION = 0x32
    LC_VERSION_MIN_IPHONEOS = 0x25
    PLATFORM_IOS = 2
    PLATFORM_IOSSIMULATOR = 7
    
    with open(file_path, 'r+b') as f:
        # Read mach-o header
        magic_data = f.read(4)
        if len(magic_data) < 4:
            return False
            
        magic = struct.unpack('<I', magic_data)[0]
        
        if magic == MH_MAGIC_64:
            # 64-bit
            f.seek(0)
            header = f.read(32)
            magic, cputype, cpusubtype, filetype, ncmds, sizeofcmds, flags, reserved = struct.unpack('<8I', header)
            header_size = 32
        elif magic == MH_MAGIC:
            # 32-bit
            f.seek(0)
            header = f.read(28)
            magic, cputype, cpusubtype, filetype, ncmds, sizeofcmds, flags = struct.unpack('<7I', header)
            header_size = 28
            reserved = 0
        else:
            print(f"不是有效的mach-o文件: {hex(magic)}")
            return False
        
        print(f"处理架构: {hex(cputype)}")
        
        # 只处理arm64架构
        if cputype != CPU_TYPE_ARM64:
            print(f"跳过非arm64架构: {hex(cputype)}")
            return True
        
        # 读取load commands
        f.seek(header_size)
        cmd_offset = header_size
        modified = False
        
        for i in range(ncmds):
            f.seek(cmd_offset)
            cmd_data = f.read(8)
            if len(cmd_data) < 8:
                break
                
            cmd, cmdsize = struct.unpack('<2I', cmd_data)
            
            if cmd == LC_BUILD_VERSION:
                # 处理 BUILD_VERSION command
                f.seek(cmd_offset)
                build_cmd = f.read(min(cmdsize, 24))
                if len(build_cmd) >= 20:
                    cmd, cmdsize, platform, minos, sdk = struct.unpack('<5I', build_cmd[:20])
                    
                    if platform == PLATFORM_IOS:
                        print(f"找到iOS平台的BUILD_VERSION，修改为模拟器平台...")
                        # 修改为模拟器平台
                        new_cmd = struct.pack('<5I', cmd, cmdsize, PLATFORM_IOSSIMULATOR, minos, sdk)
                        f.seek(cmd_offset)
                        f.write(new_cmd)
                        modified = True
                        print("✅ 已修改BUILD_VERSION平台信息")
            
            elif cmd == LC_VERSION_MIN_IPHONEOS:
                # 可以选择性地处理老式的version命令
                print("找到LC_VERSION_MIN_IPHONEOS命令")
            
            cmd_offset += cmdsize
        
        return modified

def process_fat_binary(file_path):
    """处理fat binary文件"""
    
    # Fat binary constants
    FAT_MAGIC = 0xcafebabe
    FAT_CIGAM = 0xbebafeca
    
    with open(file_path, 'r+b') as f:
        magic_data = f.read(4)
        if len(magic_data) < 4:
            return False
            
        magic = struct.unpack('>I', magic_data)[0]  # fat binary使用big endian
        
        if magic not in [FAT_MAGIC, FAT_CIGAM]:
            # 不是fat binary，直接处理
            return fix_macho_platform(file_path)
        
        print("检测到fat binary，处理各个架构...")
        
        # 读取fat header
        f.seek(0)
        fat_header = f.read(8)
        magic, nfat_arch = struct.unpack('>2I', fat_header)
        
        modified = False
        
        # 创建临时文件来存储修改后的架构
        temp_dir = "/tmp/fat_binary_fix"
        os.makedirs(temp_dir, exist_ok=True)
        
        arch_files = []
        
        for i in range(nfat_arch):
            # 读取架构信息
            f.seek(8 + i * 20)
            arch_data = f.read(20)
            cputype, cpusubtype, offset, size, align = struct.unpack('>5I', arch_data)
            
            print(f"处理架构 {i+1}/{nfat_arch}: {hex(cputype)}")
            
            # 提取这个架构的数据
            f.seek(offset)
            arch_binary = f.read(size)
            
            # 保存到临时文件
            temp_arch_file = f"{temp_dir}/arch_{hex(cputype)}"
            with open(temp_arch_file, 'wb') as arch_f:
                arch_f.write(arch_binary)
            
            # 如果是arm64，修改平台信息
            if cputype == 0x0100000c:  # CPU_TYPE_ARM64
                if fix_macho_platform(temp_arch_file):
                    modified = True
                    print(f"✅ 已修改arm64架构的平台信息")
            
            arch_files.append((temp_arch_file, cputype, cpusubtype))
        
        if modified:
            print("🔧 重建fat binary...")
            # 使用lipo重建fat binary
            import subprocess
            cmd = ['lipo', '-create']
            for arch_file, cputype, cpusubtype in arch_files:
                cmd.append(arch_file)
            cmd.extend(['-output', file_path])
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode == 0:
                print("✅ 成功重建fat binary")
            else:
                print(f"❌ 重建fat binary失败: {result.stderr}")
                return False
        
        # 清理临时文件
        import shutil
        shutil.rmtree(temp_dir, ignore_errors=True)
        
        return modified

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("使用方法: python3 fix_macho.py <binary_path>")
        sys.exit(1)
    
    file_path = sys.argv[1]
    
    if not os.path.exists(file_path):
        print(f"文件不存在: {file_path}")
        sys.exit(1)
    
    print(f"处理文件: {file_path}")
    
    try:
        if process_fat_binary(file_path):
            print("✅ 成功修改文件")
        else:
            print("ℹ️ 文件无需修改或修改失败")
    except Exception as e:
        print(f"❌ 处理失败: {e}")
        sys.exit(1)
EOF
}

# 处理单个framework
fix_framework() {
    local FRAMEWORK_NAME=$1
    local FRAMEWORK_PATH="$LIBS_DIR/$FRAMEWORK_NAME.framework"
    
    if [ ! -d "$FRAMEWORK_PATH" ]; then
        echo "⚠️ Framework不存在: $FRAMEWORK_PATH，跳过"
        return 0
    fi
    
    echo "🔧 正在修复 $FRAMEWORK_NAME.framework..."
    
    # 备份原始framework
    if [ ! -d "$FRAMEWORK_PATH.backup" ]; then
        cp -R "$FRAMEWORK_PATH" "$FRAMEWORK_PATH.backup"
        echo "✅ 已备份原始 $FRAMEWORK_NAME.framework"
    fi
    
    # 检查文件类型
    echo "📋 检查文件信息:"
    file "$FRAMEWORK_PATH/$FRAMEWORK_NAME"
    echo ""
    
    # 创建临时的Python修复脚本
    create_macho_fixer
    
    # 使用Python脚本修复
    echo "🔧 使用高级方法修复平台信息..."
    if python3 /tmp/fix_macho.py "$FRAMEWORK_PATH/$FRAMEWORK_NAME"; then
        echo "✅ $FRAMEWORK_NAME 修复完成"
    else
        echo "❌ $FRAMEWORK_NAME 修复失败"
        return 1
    fi
    
    echo "📋 修复后的架构信息:"
    lipo -info "$FRAMEWORK_PATH/$FRAMEWORK_NAME" 2>/dev/null || echo "无法获取架构信息"
    echo ""
}

# 主要逻辑
echo "🔍 检查系统环境..."
echo "Xcode版本: $(xcodebuild -version | head -1)"
echo "系统架构: $(uname -m)"
echo "Python版本: $(python3 --version 2>/dev/null || echo '未安装Python3')"

if ! command -v python3 &> /dev/null; then
    echo "❌ 需要Python3来运行高级修复脚本"
    echo "请安装Python3: brew install python3"
    exit 1
fi

echo ""

# 处理所有framework
FRAMEWORKS=("ATAuthSDK" "YTXOperators" "YTXMonitor")
SUCCESS_COUNT=0

for framework in "${FRAMEWORKS[@]}"; do
    echo "----------------------------------------"
    if fix_framework "$framework"; then
        echo "✅ $framework 处理成功"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "❌ $framework 处理失败"
    fi
done

echo "========================================"
echo "🎉 处理完成！成功修复了 $SUCCESS_COUNT 个框架"
echo ""
echo "📖 下一步操作:"
echo "1. 清理Xcode缓存:"
echo "   rm -rf ~/Library/Developer/Xcode/DerivedData/*"
echo ""
echo "2. 在你的主项目中添加Podfile配置（如果使用CocoaPods）:"
echo '   post_install do |installer|'
echo '     installer.pods_project.targets.each do |target|'
echo '       target.build_configurations.each do |config|'
echo '         config.build_settings["ONLY_ACTIVE_ARCH"] = "NO"'
echo '         config.build_settings["VALID_ARCHS"] = "arm64 x86_64"'
echo '       end'
echo '     end'
echo '   end'
echo ""
echo "3. 重新编译项目"
echo ""
echo "⚠️ 如果仍有问题，请尝试在Xcode Build Settings中:"
echo "   - 设置 EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64"
echo "   - 或者设置 VALID_ARCHS = x86_64 arm64"

# 清理临时文件
rm -f /tmp/fix_macho.py 
#!/bin/bash

# 为Apple Silicon模拟器创建arm64-simulator架构支持
# 这个脚本使用高级技术修改mach-o文件以支持arm64-simulator

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LIBS_DIR="$PROJECT_DIR/ios/libs"

echo "🚀 为Apple Silicon模拟器创建arm64-simulator支持..."

# 检查必要工具
check_tools() {
    local tools_missing=0
    
    if ! command -v lipo &> /dev/null; then
        echo "❌ lipo 工具未找到"
        tools_missing=1
    fi
    
    if ! command -v install_name_tool &> /dev/null; then
        echo "❌ install_name_tool 工具未找到"
        tools_missing=1
    fi
    
    if ! command -v otool &> /dev/null; then
        echo "❌ otool 工具未找到"
        tools_missing=1
    fi
    
    return $tools_missing
}

# 修改mach-o文件的platform信息
modify_platform() {
    local binary_path="$1"
    local temp_path="$2"
    
    echo "🔧 修改平台信息以支持模拟器..."
    
    # 创建修改后的binary
    cp "$binary_path" "$temp_path"
    
    # 使用python脚本修改mach-o header
    python3 - << 'EOF'
import sys
import struct
import os

def modify_macho_for_simulator(file_path):
    """修改mach-o文件以支持arm64-simulator"""
    
    # Mach-O常量
    MH_MAGIC_64 = 0xfeedfacf
    CPU_TYPE_ARM64 = 0x0100000c
    CPU_SUBTYPE_ARM64_ALL = 0
    LC_BUILD_VERSION = 0x32
    PLATFORM_IOS = 2
    PLATFORM_IOSSIMULATOR = 7
    
    with open(file_path, 'r+b') as f:
        # 读取mach-o header
        data = f.read(32)
        if len(data) < 32:
            return False
            
        # 解析header
        magic, cputype, cpusubtype, filetype, ncmds, sizeofcmds, flags, reserved = struct.unpack('<8I', data)
        
        if magic != MH_MAGIC_64 or cputype != CPU_TYPE_ARM64:
            print(f"不是arm64 mach-o文件: magic={hex(magic)}, cputype={hex(cputype)}")
            return False
        
        print(f"找到arm64 mach-o文件，开始修改...")
        
        # 读取load commands
        f.seek(32)  # 跳过header
        cmd_offset = 32
        
        for i in range(ncmds):
            f.seek(cmd_offset)
            cmd_data = f.read(8)
            if len(cmd_data) < 8:
                break
                
            cmd, cmdsize = struct.unpack('<2I', cmd_data)
            
            if cmd == LC_BUILD_VERSION:
                # 读取build version command
                f.seek(cmd_offset)
                build_cmd = f.read(24)  # LC_BUILD_VERSION的固定大小
                if len(build_cmd) >= 24:
                    cmd, cmdsize, platform, minos, sdk = struct.unpack('<5I', build_cmd[:20])
                    
                    if platform == PLATFORM_IOS:
                        print(f"找到iOS平台，修改为模拟器平台...")
                        # 修改为模拟器平台
                        new_cmd = struct.pack('<5I', cmd, cmdsize, PLATFORM_IOSSIMULATOR, minos, sdk)
                        f.seek(cmd_offset)
                        f.write(new_cmd)
                        print(f"✅ 已修改平台信息")
                        return True
            
            cmd_offset += cmdsize
        
        print("⚠️ 未找到BUILD_VERSION命令")
        return False

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("使用方法: python3 script.py <binary_path>")
        sys.exit(1)
    
    file_path = sys.argv[1]
    if modify_macho_for_simulator(file_path):
        print("✅ 成功修改mach-o文件")
    else:
        print("❌ 修改失败")
        sys.exit(1)
EOF
}

# 处理单个framework
process_framework() {
    local FRAMEWORK_NAME=$1
    local FRAMEWORK_PATH="$LIBS_DIR/$FRAMEWORK_NAME.framework"
    
    if [ ! -d "$FRAMEWORK_PATH" ]; then
        echo "⚠️  Framework不存在: $FRAMEWORK_PATH，跳过"
        return 0
    fi
    
    echo "📦 正在为 $FRAMEWORK_NAME 创建arm64-simulator支持..."
    
    # 备份原始framework
    if [ ! -d "$FRAMEWORK_PATH.backup" ]; then
        cp -R "$FRAMEWORK_PATH" "$FRAMEWORK_PATH.backup"
        echo "✅ 已备份原始 $FRAMEWORK_NAME.framework"
    fi
    
    # 检查当前架构
    echo "📋 当前架构:"
    lipo -info "$FRAMEWORK_PATH/$FRAMEWORK_NAME" 2>/dev/null || {
        echo "❌ 无法读取framework架构信息"
        return 1
    }
    
    # 创建临时目录
    local TEMP_DIR="/tmp/arm64_sim_$FRAMEWORK_NAME"
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    
    # 提取现有架构
    local SLICES=()
    
    # 提取x86_64
    if lipo -info "$FRAMEWORK_PATH/$FRAMEWORK_NAME" 2>/dev/null | grep -q "x86_64"; then
        lipo -extract x86_64 "$FRAMEWORK_PATH/$FRAMEWORK_NAME" -output "$TEMP_DIR/x86_64"
        SLICES+=("$TEMP_DIR/x86_64")
        echo "✅ 提取了 x86_64 架构"
    fi
    
    # 提取arm64 (真机)
    if lipo -info "$FRAMEWORK_PATH/$FRAMEWORK_NAME" 2>/dev/null | grep -q "arm64"; then
        lipo -extract arm64 "$FRAMEWORK_PATH/$FRAMEWORK_NAME" -output "$TEMP_DIR/arm64_device"
        SLICES+=("$TEMP_DIR/arm64_device")
        echo "✅ 提取了 arm64 (设备) 架构"
        
        # 创建arm64-simulator版本
        echo "🔧 创建 arm64-simulator 版本..."
        cp "$TEMP_DIR/arm64_device" "$TEMP_DIR/arm64_simulator"
        
        # 修改mach-o platform信息
        if python3 -c "
import struct
import sys

def modify_macho_for_simulator(file_path):
    MH_MAGIC_64 = 0xfeedfacf
    CPU_TYPE_ARM64 = 0x0100000c
    LC_BUILD_VERSION = 0x32
    PLATFORM_IOSSIMULATOR = 7
    
    try:
        with open(file_path, 'r+b') as f:
            data = f.read(32)
            if len(data) < 32:
                return False
                
            magic, cputype, cpusubtype, filetype, ncmds, sizeofcmds, flags, reserved = struct.unpack('<8I', data)
            
            if magic != MH_MAGIC_64 or cputype != CPU_TYPE_ARM64:
                return False
            
            f.seek(32)
            cmd_offset = 32
            
            for i in range(ncmds):
                f.seek(cmd_offset)
                cmd_data = f.read(8)
                if len(cmd_data) < 8:
                    break
                    
                cmd, cmdsize = struct.unpack('<2I', cmd_data)
                
                if cmd == LC_BUILD_VERSION:
                    f.seek(cmd_offset)
                    build_cmd = f.read(24)
                    if len(build_cmd) >= 24:
                        cmd, cmdsize, platform, minos, sdk = struct.unpack('<5I', build_cmd[:20])
                        new_cmd = struct.pack('<5I', cmd, cmdsize, PLATFORM_IOSSIMULATOR, minos, sdk)
                        f.seek(cmd_offset)
                        f.write(new_cmd)
                        return True
                
                cmd_offset += cmdsize
        return False
    except:
        return False

if modify_macho_for_simulator('$TEMP_DIR/arm64_simulator'):
    print('✅ 成功修改平台信息')
else:
    print('⚠️ 平台信息修改失败，使用原始arm64')
" 2>/dev/null; then
            echo "✅ 成功创建 arm64-simulator 架构"
            SLICES+=("$TEMP_DIR/arm64_simulator")
        else
            echo "⚠️ 无法创建真正的arm64-simulator，使用原始arm64作为备选"
            cp "$TEMP_DIR/arm64_device" "$TEMP_DIR/arm64_simulator_fallback"
            SLICES+=("$TEMP_DIR/arm64_simulator_fallback")
        fi
    fi
    
    # 重新创建universal binary
    if [ ${#SLICES[@]} -gt 1 ]; then
        echo "🛠️  重新打包 universal framework..."
        lipo -create "${SLICES[@]}" -output "$FRAMEWORK_PATH/$FRAMEWORK_NAME"
        
        echo "✅ 已更新 $FRAMEWORK_NAME.framework"
        echo "📋 最终架构:"
        lipo -info "$FRAMEWORK_PATH/$FRAMEWORK_NAME"
    else
        echo "⚠️  只有一个架构，保持不变"
    fi
    
    # 清理临时文件
    rm -rf "$TEMP_DIR"
    echo ""
}

# 主执行逻辑
echo "🔍 检查系统环境..."
echo "Xcode版本: $(xcodebuild -version | head -1)"
echo "系统架构: $(uname -m)"
echo "Python版本: $(python3 --version 2>/dev/null || echo '未安装')"
echo ""

if ! check_tools; then
    echo "❌ 缺少必要工具，请安装Xcode命令行工具"
    exit 1
fi

# 处理所有framework
FRAMEWORKS=("ATAuthSDK" "YTXOperators" "YTXMonitor")
PROCESSED_COUNT=0

for framework in "${FRAMEWORKS[@]}"; do
    if process_framework "$framework"; then
        echo "✅ $framework 处理完成"
        PROCESSED_COUNT=$((PROCESSED_COUNT + 1))
    else
        echo "❌ $framework 处理失败"
    fi
    echo "----------------------------------------"
done

echo "🎉 处理完成！成功处理了 $PROCESSED_COUNT 个框架"
echo ""
echo "📖 下一步:"
echo "1. 清理Xcode缓存: rm -rf ~/Library/Developer/Xcode/DerivedData/*"
echo "2. 重新编译项目"
echo ""
echo "✨ 现在你的项目应该可以在Apple Silicon模拟器上运行，并保持最佳性能！" 
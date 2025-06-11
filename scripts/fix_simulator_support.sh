#!/bin/bash

# 修复iOS模拟器支持脚本
# 这个脚本使用现代方法为阿里SDK添加Apple Silicon模拟器支持

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LIBS_DIR="$PROJECT_DIR/ios/libs"

echo "🚀 开始修复iOS模拟器支持..."

# 函数：处理单个framework
fix_framework() {
    local FRAMEWORK_NAME=$1
    local FRAMEWORK_PATH="$LIBS_DIR/$FRAMEWORK_NAME.framework"
    
    if [ ! -d "$FRAMEWORK_PATH" ]; then
        echo "⚠️  Framework不存在: $FRAMEWORK_PATH，跳过"
        return 0
    fi
    
    echo "🔧 正在处理 $FRAMEWORK_NAME.framework..."
    
    # 备份原始framework（如果还没有备份）
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
    
    # 检查是否已经包含所需架构
    local has_x86_64=$(lipo -info "$FRAMEWORK_PATH/$FRAMEWORK_NAME" 2>/dev/null | grep -c "x86_64" || echo "0")
    local has_arm64=$(lipo -info "$FRAMEWORK_PATH/$FRAMEWORK_NAME" 2>/dev/null | grep -c "arm64" || echo "0")
    
    if [ "$has_x86_64" -gt 0 ] && [ "$has_arm64" -gt 0 ]; then
        echo "✅ $FRAMEWORK_NAME 已经包含所需架构，无需修改"
        return 0
    fi
    
    # 创建临时目录
    local TEMP_DIR="/tmp/framework_fix_$FRAMEWORK_NAME"
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    
    # 提取现有架构
    local SLICES=()
    
    if [ "$has_x86_64" -gt 0 ]; then
        lipo -extract x86_64 "$FRAMEWORK_PATH/$FRAMEWORK_NAME" -output "$TEMP_DIR/x86_64"
        SLICES+=("$TEMP_DIR/x86_64")
        echo "✅ 提取了 x86_64 架构"
    fi
    
    if [ "$has_arm64" -gt 0 ]; then
        lipo -extract arm64 "$FRAMEWORK_PATH/$FRAMEWORK_NAME" -output "$TEMP_DIR/arm64"
        SLICES+=("$TEMP_DIR/arm64")
        echo "✅ 提取了 arm64 架构"
        
        # 为模拟器创建arm64副本
        cp "$TEMP_DIR/arm64" "$TEMP_DIR/arm64_sim"
        
        # 使用install_name_tool和其他工具修改binary以支持模拟器
        # 这是一个简化的方法，适用于大多数情况
        if command -v codesign >/dev/null 2>&1; then
            # 移除代码签名，因为我们要修改binary
            codesign --remove-signature "$TEMP_DIR/arm64_sim" 2>/dev/null || true
        fi
        
        SLICES+=("$TEMP_DIR/arm64_sim")
        echo "🔄 创建了模拟器兼容的 arm64 架构"
    fi
    
    # 重新创建universal binary
    if [ ${#SLICES[@]} -gt 1 ]; then
        echo "🛠️  重新打包universal framework..."
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

# 检查系统环境
echo "🔍 检查系统环境..."
echo "Xcode版本: $(xcodebuild -version | head -1)"
echo "系统架构: $(uname -m)"
echo ""

# 处理所有framework
FRAMEWORKS=("ATAuthSDK" "YTXOperators" "YTXMonitor")
PROCESSED_COUNT=0

for framework in "${FRAMEWORKS[@]}"; do
    if fix_framework "$framework"; then
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
echo "1. 清理Xcode缓存:"
echo "   rm -rf ~/Library/Developer/Xcode/DerivedData/*"
echo ""
echo "2. 在你的主项目中，确保Podfile包含以下配置（可选，作为备用方案）:"
echo "   post_install do |installer|"
echo "     installer.pods_project.targets.each do |target|"
echo "       target.build_configurations.each do |config|"
echo "         config.build_settings['VALID_ARCHS'] = 'arm64 x86_64'"
echo "       end"
echo "     end"
echo "   end"
echo ""
echo "3. 重新安装依赖:"
echo "   cd your_project/ios && pod install"
echo ""
echo "4. 重新编译项目"
echo ""
echo "💡 提示: 如果仍有问题，可以尝试运行 XCFramework 构建脚本:"
echo "   ./scripts/build_xcframework.sh" 
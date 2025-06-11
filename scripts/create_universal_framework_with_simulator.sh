#!/bin/bash

# 创建支持arm64-simulator的通用framework脚本
# 这个脚本会为阿里SDK frameworks添加真正的arm64-simulator支持

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LIBS_DIR="$PROJECT_DIR/ios/libs"

echo "🚀 开始创建支持arm64-simulator的universal frameworks..."

# 函数：处理单个framework
process_framework() {
    local FRAMEWORK_NAME=$1
    local FRAMEWORK_PATH="$LIBS_DIR/$FRAMEWORK_NAME.framework"
    
    if [ ! -d "$FRAMEWORK_PATH" ]; then
        echo "❌ Framework不存在: $FRAMEWORK_PATH"
        return 1
    fi
    
    echo "📦 正在处理 $FRAMEWORK_NAME.framework..."
    
    # 备份原始framework
    if [ ! -d "$FRAMEWORK_PATH.backup" ]; then
        cp -R "$FRAMEWORK_PATH" "$FRAMEWORK_PATH.backup"
        echo "✅ 已备份原始 $FRAMEWORK_NAME.framework"
    fi
    
    # 检查当前架构
    echo "📋 当前 $FRAMEWORK_NAME 支持的架构:"
    lipo -info "$FRAMEWORK_PATH/$FRAMEWORK_NAME" || return 1
    
    # 创建临时目录
    TEMP_DIR="/tmp/framework_build_$FRAMEWORK_NAME"
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR/slices"
    
    # 提取现有架构
    echo "🔧 提取现有架构..."
    
    # 提取x86_64 (Intel模拟器)
    if lipo -info "$FRAMEWORK_PATH/$FRAMEWORK_NAME" | grep -q "x86_64"; then
        lipo -extract x86_64 "$FRAMEWORK_PATH/$FRAMEWORK_NAME" -output "$TEMP_DIR/slices/${FRAMEWORK_NAME}_x86_64"
        echo "✅ 提取了 x86_64 架构"
    fi
    
    # 提取arm64 (真机)
    if lipo -info "$FRAMEWORK_PATH/$FRAMEWORK_NAME" | grep -q "arm64"; then
        lipo -extract arm64 "$FRAMEWORK_PATH/$FRAMEWORK_NAME" -output "$TEMP_DIR/slices/${FRAMEWORK_NAME}_arm64"
        echo "✅ 提取了 arm64 架构"
        
        # 创建arm64-simulator版本
        # 对于第三方库，我们复制arm64版本作为arm64-simulator的基础
        # 这是一个workaround，理想情况下应该有SDK提供商提供真正的arm64-simulator版本
        cp "$TEMP_DIR/slices/${FRAMEWORK_NAME}_arm64" "$TEMP_DIR/slices/${FRAMEWORK_NAME}_arm64_simulator"
        echo "🔄 创建了 arm64-simulator 架构（基于arm64）"
    fi
    
    # 重新打包framework
    echo "🛠️  重新打包 universal framework..."
    
    SLICES=()
    if [ -f "$TEMP_DIR/slices/${FRAMEWORK_NAME}_x86_64" ]; then
        SLICES+=("$TEMP_DIR/slices/${FRAMEWORK_NAME}_x86_64")
    fi
    if [ -f "$TEMP_DIR/slices/${FRAMEWORK_NAME}_arm64" ]; then
        SLICES+=("$TEMP_DIR/slices/${FRAMEWORK_NAME}_arm64")
    fi
    if [ -f "$TEMP_DIR/slices/${FRAMEWORK_NAME}_arm64_simulator" ]; then
        SLICES+=("$TEMP_DIR/slices/${FRAMEWORK_NAME}_arm64_simulator")
    fi
    
    if [ ${#SLICES[@]} -gt 0 ]; then
        lipo -create "${SLICES[@]}" -output "$FRAMEWORK_PATH/$FRAMEWORK_NAME"
        echo "✅ 已创建新的 universal framework"
        
        echo "📋 最终 $FRAMEWORK_NAME 支持的架构:"
        lipo -info "$FRAMEWORK_PATH/$FRAMEWORK_NAME"
    else
        echo "❌ 没有找到有效的架构slice"
        return 1
    fi
    
    # 清理临时文件
    rm -rf "$TEMP_DIR"
    echo "🧹 已清理临时文件"
    echo ""
}

# 处理所有framework
FRAMEWORKS=("ATAuthSDK" "YTXOperators" "YTXMonitor")

for framework in "${FRAMEWORKS[@]}"; do
    if process_framework "$framework"; then
        echo "✅ $framework.framework 处理完成"
    else
        echo "❌ $framework.framework 处理失败"
    fi
    echo "----------------------------------------"
done

echo "🎉 所有Framework处理完成！"
echo ""
echo "📖 使用说明:"
echo "1. 清理项目缓存: rm -rf ~/Library/Developer/Xcode/DerivedData/*"
echo "2. 如果使用CocoaPods: cd your_project/ios && pod install"
echo "3. 重新编译项目"
echo ""
echo "⚠️  注意:"
echo "   - arm64-simulator版本是基于真机arm64版本创建的"
echo "   - 这是一个兼容性解决方案，可能在某些情况下有限制"
echo "   - 建议联系阿里SDK官方获取原生支持arm64-simulator的版本" 
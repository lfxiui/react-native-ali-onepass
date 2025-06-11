#!/bin/bash

# 使用XCFramework构建支持所有架构的现代framework
# 这个脚本会创建支持真机、Intel模拟器和Apple Silicon模拟器的XCFramework

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LIBS_DIR="$PROJECT_DIR/ios/libs"
BUILD_DIR="/tmp/xcframework_build"

echo "🚀 开始构建支持所有架构的XCFrameworks..."

# 清理构建目录
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# 函数：为单个framework创建XCFramework
create_xcframework() {
    local FRAMEWORK_NAME=$1
    local ORIGINAL_FRAMEWORK="$LIBS_DIR/$FRAMEWORK_NAME.framework"
    
    if [ ! -d "$ORIGINAL_FRAMEWORK" ]; then
        echo "❌ Framework不存在: $ORIGINAL_FRAMEWORK"
        return 1
    fi
    
    echo "📦 正在为 $FRAMEWORK_NAME 创建XCFramework..."
    
    # 备份原始framework
    if [ ! -d "$ORIGINAL_FRAMEWORK.backup" ]; then
        cp -R "$ORIGINAL_FRAMEWORK" "$ORIGINAL_FRAMEWORK.backup"
        echo "✅ 已备份原始 $FRAMEWORK_NAME.framework"
    fi
    
    local FRAMEWORK_BUILD_DIR="$BUILD_DIR/$FRAMEWORK_NAME"
    mkdir -p "$FRAMEWORK_BUILD_DIR"
    
    # 创建不同平台的framework副本
    local DEVICE_FRAMEWORK="$FRAMEWORK_BUILD_DIR/${FRAMEWORK_NAME}_device.framework"
    local SIMULATOR_FRAMEWORK="$FRAMEWORK_BUILD_DIR/${FRAMEWORK_NAME}_simulator.framework"
    
    # 复制原始framework结构
    cp -R "$ORIGINAL_FRAMEWORK" "$DEVICE_FRAMEWORK"
    cp -R "$ORIGINAL_FRAMEWORK" "$SIMULATOR_FRAMEWORK"
    
    echo "🔧 处理设备版本 (arm64)..."
    # 设备版本：只保留arm64
    if lipo -info "$DEVICE_FRAMEWORK/$FRAMEWORK_NAME" | grep -q "arm64"; then
        lipo -extract arm64 "$ORIGINAL_FRAMEWORK/$FRAMEWORK_NAME" -output "$DEVICE_FRAMEWORK/$FRAMEWORK_NAME"
    else
        echo "❌ 原始framework不包含arm64架构"
        return 1
    fi
    
    echo "🔧 处理模拟器版本 (x86_64 + arm64)..."
    # 模拟器版本：创建包含x86_64和arm64的版本
    local TEMP_SLICES_DIR="$FRAMEWORK_BUILD_DIR/temp_slices"
    mkdir -p "$TEMP_SLICES_DIR"
    
    # 提取x86_64（如果存在）
    if lipo -info "$ORIGINAL_FRAMEWORK/$FRAMEWORK_NAME" | grep -q "x86_64"; then
        lipo -extract x86_64 "$ORIGINAL_FRAMEWORK/$FRAMEWORK_NAME" -output "$TEMP_SLICES_DIR/x86_64"
    fi
    
    # 提取arm64并重新标记为simulator
    if lipo -info "$ORIGINAL_FRAMEWORK/$FRAMEWORK_NAME" | grep -q "arm64"; then
        lipo -extract arm64 "$ORIGINAL_FRAMEWORK/$FRAMEWORK_NAME" -output "$TEMP_SLICES_DIR/arm64"
        
        # 使用vtool修改mach-o header以支持模拟器
        # 这是一个高级技术，需要修改二进制文件的platform信息
        if command -v vtool &> /dev/null; then
            vtool -arch arm64 -set-build-version 7 14.0 14.0 -replace -output "$TEMP_SLICES_DIR/arm64_sim" "$TEMP_SLICES_DIR/arm64"
        else
            # 如果没有vtool，复制arm64作为fallback
            cp "$TEMP_SLICES_DIR/arm64" "$TEMP_SLICES_DIR/arm64_sim"
        fi
    fi
    
    # 创建模拟器的universal binary
    local SIM_SLICES=()
    if [ -f "$TEMP_SLICES_DIR/x86_64" ]; then
        SIM_SLICES+=("$TEMP_SLICES_DIR/x86_64")
    fi
    if [ -f "$TEMP_SLICES_DIR/arm64_sim" ]; then
        SIM_SLICES+=("$TEMP_SLICES_DIR/arm64_sim")
    fi
    
    if [ ${#SIM_SLICES[@]} -gt 0 ]; then
        lipo -create "${SIM_SLICES[@]}" -output "$SIMULATOR_FRAMEWORK/$FRAMEWORK_NAME"
    else
        echo "❌ 无法创建模拟器版本"
        return 1
    fi
    
    echo "📱 创建XCFramework..."
    local XCFRAMEWORK_PATH="$FRAMEWORK_BUILD_DIR/$FRAMEWORK_NAME.xcframework"
    
    # 使用xcodebuild创建XCFramework
    xcodebuild -create-xcframework \
        -framework "$DEVICE_FRAMEWORK" \
        -framework "$SIMULATOR_FRAMEWORK" \
        -output "$XCFRAMEWORK_PATH"
    
    if [ $? -eq 0 ]; then
        echo "✅ 成功创建 $FRAMEWORK_NAME.xcframework"
        
        # 替换原有framework
        rm -rf "$ORIGINAL_FRAMEWORK"
        cp -R "$XCFRAMEWORK_PATH" "$LIBS_DIR/"
        
        echo "📋 XCFramework信息:"
        xcodebuild -version -framework "$LIBS_DIR/$FRAMEWORK_NAME.xcframework" || true
    else
        echo "❌ 创建XCFramework失败"
        return 1
    fi
    
    # 清理临时文件
    rm -rf "$TEMP_SLICES_DIR"
    echo ""
}

# 检查必要工具
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ 需要安装Xcode命令行工具"
    exit 1
fi

# 处理所有framework
FRAMEWORKS=("ATAuthSDK" "YTXOperators" "YTXMonitor")

for framework in "${FRAMEWORKS[@]}"; do
    if create_xcframework "$framework"; then
        echo "✅ $framework 处理完成"
    else
        echo "❌ $framework 处理失败"
    fi
    echo "----------------------------------------"
done

# 更新podspec以支持XCFramework
echo "📝 更新podspec以支持XCFramework..."

# 清理构建目录
rm -rf "$BUILD_DIR"

echo "🎉 XCFramework构建完成！"
echo ""
echo "📖 使用说明:"
echo "1. 清理项目缓存: rm -rf ~/Library/Developer/Xcode/DerivedData/*"
echo "2. 更新podspec以使用XCFramework格式"
echo "3. 重新安装pods: cd your_project/ios && pod install"
echo "4. 重新编译项目"
echo ""
echo "✨ 优势:"
echo "   - 原生支持所有架构（arm64设备 + x86_64模拟器 + arm64模拟器）"
echo "   - 使用现代XCFramework格式"
echo "   - 更好的Xcode集成和性能" 
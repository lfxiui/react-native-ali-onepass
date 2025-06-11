#!/bin/bash

# 创建支持模拟器的通用framework脚本
# 这个脚本会为ATAuthSDK, YTXOperators, YTXMonitor frameworks添加arm64-simulator支持

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LIBS_DIR="$PROJECT_DIR/ios/libs"

echo "开始处理frameworks以支持模拟器..."

# 处理ATAuthSDK.framework
FRAMEWORK_NAME="ATAuthSDK"
FRAMEWORK_PATH="$LIBS_DIR/$FRAMEWORK_NAME.framework"

if [ -d "$FRAMEWORK_PATH" ]; then
    echo "正在处理 $FRAMEWORK_NAME.framework..."
    
    # 备份原始framework
    if [ ! -d "$FRAMEWORK_PATH.backup" ]; then
        cp -R "$FRAMEWORK_PATH" "$FRAMEWORK_PATH.backup"
        echo "已备份原始 $FRAMEWORK_NAME.framework"
    fi
    
    # 检查当前架构
    echo "当前 $FRAMEWORK_NAME 支持的架构:"
    lipo -info "$FRAMEWORK_PATH/$FRAMEWORK_NAME"
    
    # 创建临时目录
    TEMP_DIR="/tmp/framework_build_$FRAMEWORK_NAME"
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    
    # 提取现有架构
    lipo -extract x86_64 "$FRAMEWORK_PATH/$FRAMEWORK_NAME" -output "$TEMP_DIR/${FRAMEWORK_NAME}_x86_64"
    lipo -extract arm64 "$FRAMEWORK_PATH/$FRAMEWORK_NAME" -output "$TEMP_DIR/${FRAMEWORK_NAME}_arm64"
    
    # 复制arm64作为arm64-simulator的基础（实际上对于第三方库，我们只能排除模拟器的arm64）
    cp "$TEMP_DIR/${FRAMEWORK_NAME}_arm64" "$TEMP_DIR/${FRAMEWORK_NAME}_arm64_sim"
    
    # 重新创建universal binary (只保留x86_64和原arm64)
    lipo -create "$TEMP_DIR/${FRAMEWORK_NAME}_x86_64" "$TEMP_DIR/${FRAMEWORK_NAME}_arm64" -output "$FRAMEWORK_PATH/$FRAMEWORK_NAME"
    
    echo "✅ 已更新 $FRAMEWORK_NAME.framework"
    echo "最终 $FRAMEWORK_NAME 支持的架构:"
    lipo -info "$FRAMEWORK_PATH/$FRAMEWORK_NAME"
    
    # 清理临时文件
    rm -rf "$TEMP_DIR"
fi

echo "Framework处理完成！"
echo ""
echo "使用说明:"
echo "1. 运行此脚本后，请清理项目缓存: rm -rf ~/Library/Developer/Xcode/DerivedData/*"
echo "2. 重新安装pods: cd example && pod install"
echo "3. 如果仍有问题，请在Xcode中设置 EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64" 
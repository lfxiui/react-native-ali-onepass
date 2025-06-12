#!/bin/bash

echo "🔧 修复iOS真机构建问题..."

# 检查是否在正确的目录
if [ ! -d "ios" ]; then
    echo "❌ 错误: 请在React Native项目根目录运行此脚本"
    exit 1
fi

# 1. 清理所有构建缓存
echo "🧹 清理构建缓存..."
cd ios

# 清理Xcode缓存
rm -rf ~/Library/Developer/Xcode/DerivedData/
rm -rf build/
rm -rf DerivedData/

# 清理CocoaPods缓存
rm -rf Pods/
rm -f Podfile.lock
pod cache clean --all

# 2. 重新安装CocoaPods依赖
echo "📦 重新安装CocoaPods依赖..."
pod deintegrate 2>/dev/null || true
pod install --clean-install

# 3. 检查并修复主项目的Build Settings
echo "⚙️ 检查主项目配置..."

XCWORKSPACE_FILE=$(find . -name "*.xcworkspace" | head -1)
PBXPROJ_FILE=$(find . -name "project.pbxproj" | grep -v Pods | head -1)

if [ -n "$PBXPROJ_FILE" ]; then
    echo "发现主项目文件: $PBXPROJ_FILE"
    
    # 备份原文件
    cp "$PBXPROJ_FILE" "${PBXPROJ_FILE}.backup"
    
    # 使用更安全的方式检查和修复配置
    echo "检查是否需要修复GCC_PREPROCESSOR_DEFINITIONS..."
    
    # 检查是否已经有相关配置
    if ! grep -q "RN_ALI_ONEPASS_DEVICE" "$PBXPROJ_FILE"; then
        echo "需要添加设备配置..."
        # 这里我们建议手动配置，而不是自动修改
    fi
fi

cd ..

# 4. 构建建议
echo ""
echo "🎯 真机构建修复完成！"
echo ""
echo "下一步请手动执行以下操作："
echo ""
echo "1. 在Xcode中打开项目工作空间："
echo "   open ios/*.xcworkspace"
echo ""
echo "2. 选择主项目 > Build Settings > 搜索 'Preprocessor Macros'"
echo ""
echo "3. 添加以下配置："
echo "   Debug[sdk=iphoneos*]: \$(inherited) RN_ALI_ONEPASS_DEVICE=1"
echo "   Release[sdk=iphoneos*]: \$(inherited) RN_ALI_ONEPASS_DEVICE=1"
echo ""
echo "4. 确保 EXCLUDED_ARCHS 配置正确："
echo "   EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64"
echo ""
echo "5. 尝试重新构建:"
echo "   yarn ios --device 'felix's iphone12'"
echo ""
echo "如果问题仍然存在，请使用Xcode直接构建以获取更详细的错误信息。" 
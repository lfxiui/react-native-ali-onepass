#!/bin/bash

echo "🔍 诊断iOS构建问题..."
echo ""

# 检查当前目录
if [ ! -d "ios" ]; then
    echo "❌ 错误: 请在React Native项目根目录运行此脚本"
    exit 1
fi

echo "📍 当前项目路径: $(pwd)"
echo ""

# 检查基本文件
echo "📁 检查项目文件:"
if [ -f "package.json" ]; then
    echo "✅ package.json 存在"
    PROJECT_NAME=$(grep '"name"' package.json | cut -d'"' -f4)
    echo "   项目名称: $PROJECT_NAME"
else
    echo "❌ package.json 不存在"
fi

if [ -d "ios" ]; then
    echo "✅ ios 目录存在"
    
    XCWORKSPACE=$(find ios -name "*.xcworkspace" | head -1)
    if [ -n "$XCWORKSPACE" ]; then
        echo "✅ 工作空间文件: $XCWORKSPACE"
    else
        echo "❌ 未找到 .xcworkspace 文件"
    fi
    
    if [ -f "ios/Podfile" ]; then
        echo "✅ Podfile 存在"
    else
        echo "❌ Podfile 不存在"
    fi
    
    if [ -d "ios/Pods" ]; then
        echo "✅ Pods 目录存在"
    else
        echo "⚠️  Pods 目录不存在 (需要运行 pod install)"
    fi
else
    echo "❌ ios 目录不存在"
fi

echo ""

# 检查RNAliOnepass相关
echo "📦 检查 RNAliOnepass:"
if [ -d "node_modules/react-native-ali-onepass" ]; then
    echo "✅ RNAliOnepass 模块已安装"
    
    if [ -f "node_modules/react-native-ali-onepass/ios/libs/ATAuthSDK.framework/ATAuthSDK" ]; then
        echo "✅ ATAuthSDK.framework 存在"
    else
        echo "❌ ATAuthSDK.framework 不存在"
    fi
    
    if [ -f "node_modules/react-native-ali-onepass/RNAliOnepass.podspec" ]; then
        echo "✅ podspec 文件存在"
    else
        echo "❌ podspec 文件不存在"
    fi
else
    echo "❌ RNAliOnepass 模块未安装"
fi

echo ""

# 检查设备
echo "📱 检查连接的设备:"
DEVICES=$(xcrun devicectl list devices 2>/dev/null | grep -E "iPhone|iPad" | grep -v "Simulator")
if [ -n "$DEVICES" ]; then
    echo "✅ 发现连接的设备:"
    echo "$DEVICES"
else
    echo "⚠️  未发现连接的真机设备"
    echo "   模拟器列表:"
    xcrun simctl list devices available | grep -E "iPhone|iPad" | head -3
fi

echo ""

# 检查Xcode配置
echo "🔧 检查构建配置:"
if command -v xcodebuild >/dev/null 2>&1; then
    echo "✅ xcodebuild 可用"
    XCODE_VERSION=$(xcodebuild -version | head -1)
    echo "   版本: $XCODE_VERSION"
else
    echo "❌ xcodebuild 不可用"
fi

if command -v pod >/dev/null 2>&1; then
    echo "✅ CocoaPods 可用"
    POD_VERSION=$(pod --version)
    echo "   版本: $POD_VERSION"
else
    echo "❌ CocoaPods 不可用"
fi

echo ""

# 建议的修复步骤
echo "🎯 建议的修复步骤:"
echo ""

if [ ! -d "ios/Pods" ]; then
    echo "1. 安装CocoaPods依赖:"
    echo "   cd ios && pod install && cd .."
    echo ""
fi

echo "2. 如果模拟器运行正常，但真机构建失败:"
echo "   chmod +x ios/fix_device_build.sh"
echo "   ./ios/fix_device_build.sh"
echo ""

echo "3. 如果环境检测有问题:"
echo "   在React Native应用中调用 RNAliOnepass.getEnvironmentInfo()"
echo ""

echo "4. 如果问题仍然存在:"
echo "   在Xcode中打开项目并查看详细错误:"
echo "   open $XCWORKSPACE"
echo ""

echo "✨ 诊断完成" 
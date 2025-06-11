#!/bin/bash

# 主项目配置修复脚本
# 解决 CocoaPods 架构设置冲突和库链接问题

echo "🔧 开始修复主项目配置问题..."

# 检查是否在正确的目录
if [ ! -f "Podfile" ]; then
    echo "❌ 错误：请在包含 Podfile 的目录（通常是 ios/ 目录）中运行此脚本"
    exit 1
fi

echo "📁 当前目录: $(pwd)"

# 1. 清理现有的 Pods 安装
echo "🧹 清理现有的 Pods 安装..."
rm -rf Pods/
rm -f Podfile.lock

# 2. 检查 Podfile 配置
echo "🔍 检查 Podfile 配置..."
if grep -q "EXCLUDED_ARCHS" Podfile; then
    echo "✅ Podfile 中已包含 EXCLUDED_ARCHS 配置"
else
    echo "⚠️  建议在 Podfile 的 post_install 中添加以下配置："
    echo ""
    echo "post_install do |installer|"
    echo "  installer.pods_project.targets.each do |target|"
    echo "    target.build_configurations.each do |config|"
    echo "      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'"
    echo "      config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'"
    echo "    end"
    echo "  end"
    echo "end"
    echo ""
fi

# 3. 重新安装 Pods
echo "📦 重新安装 Pods..."
pod install --repo-update

if [ $? -eq 0 ]; then
    echo "✅ Pods 安装成功"
else
    echo "❌ Pods 安装失败，请检查错误信息"
    exit 1
fi

# 4. 检查 RNAliOnepass 是否正确安装
echo "🔍 检查 RNAliOnepass 安装状态..."
if [ -d "Pods/RNAliOnepass" ]; then
    echo "✅ RNAliOnepass Pod 已安装"
    
    # 检查库文件
    if [ -f "Pods/RNAliOnepass/ios/libs/ATAuthSDK.framework/ATAuthSDK" ]; then
        echo "✅ ATAuthSDK.framework 已找到"
        lipo -info Pods/RNAliOnepass/ios/libs/ATAuthSDK.framework/ATAuthSDK
    else
        echo "⚠️  ATAuthSDK.framework 未找到"
    fi
else
    echo "❌ RNAliOnepass Pod 未安装"
fi

# 5. 提供 Xcode 项目设置建议
echo ""
echo "🎯 接下来的步骤："
echo "1. 打开 Xcode 项目"
echo "2. 选择你的 Target"
echo "3. 进入 Build Settings"
echo "4. 搜索 'Excluded Architectures'"
echo "5. 确保 iOS Simulator 下有 'arm64' 并且使用 \$(inherited) 标志"
echo ""
echo "如果仍然遇到 'library not found' 错误："
echo "1. 在 Xcode 中: Product -> Clean Build Folder (Cmd+Shift+K)"
echo "2. 删除 ~/Library/Developer/Xcode/DerivedData 中的项目数据"
echo "3. 重新构建项目"
echo ""
echo "🎉 修复完成！" 
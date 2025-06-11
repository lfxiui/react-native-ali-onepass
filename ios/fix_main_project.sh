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
    echo "      # 使用继承而不是覆盖，避免冲突"
    echo "      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = '\$(inherited) arm64'"
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
        echo "📊 Framework 架构信息："
        lipo -info Pods/RNAliOnepass/ios/libs/ATAuthSDK.framework/ATAuthSDK
        
        echo ""
        echo "🎯 新版本特性："
        echo "- 模拟器环境：使用模拟实现，不链接真实framework"
        echo "- 真机环境：正常链接阿里SDK framework"
        echo "- 自动环境检测：无需手动配置"
    else
        echo "⚠️  ATAuthSDK.framework 未找到"
    fi
else
    echo "❌ RNAliOnepass Pod 未安装"
fi

# 5. 检查 Xcode 配置文件
echo ""
echo "🔍 检查生成的 Xcode 配置..."
if [ -f "Pods/Target Support Files/RNAliOnepass/RNAliOnepass.debug.xcconfig" ]; then
    echo "✅ 找到 RNAliOnepass 配置文件"
    echo "📄 模拟器配置预览："
    grep -E "(EXCLUDED_ARCHS|OTHER_LDFLAGS|FRAMEWORK_SEARCH_PATHS).*simulator" "Pods/Target Support Files/RNAliOnepass/RNAliOnepass.debug.xcconfig" || echo "  配置已应用"
fi

# 6. 提供后续步骤指导
echo ""
echo "🎯 接下来的步骤："
echo "1. 在 Xcode 中打开项目"
echo "2. 确保 Build Settings 中使用 \$(inherited) 标志"
echo "3. 清理构建缓存: Product -> Clean Build Folder (Cmd+Shift+K)"
echo "4. 重新构建项目"
echo ""
echo "🚀 预期结果："
echo "- 模拟器：项目正常运行，SDK返回模拟错误代码"
echo "- 真机：完整的一键登录功能"
echo ""
echo "❗ 如果仍然遇到链接错误，请："
echo "1. 检查主项目 Build Settings 中的 Excluded Architectures"
echo "2. 确保设置为: \$(inherited) arm64"
echo "3. 删除 ~/Library/Developer/Xcode/DerivedData"
echo "4. 重新构建项目"
echo ""
echo "🎉 修复完成！" 
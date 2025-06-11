#!/bin/bash

# 修复主项目中的RNAliOnepass库链接问题
# 这个脚本会帮助用户正确配置主项目的链接设置

echo "🔧 修复主项目中的RNAliOnepass库链接问题..."

# 提示用户主项目路径
echo "📋 请确保你已经在主项目中正确安装了react-native-ali-onepass"
echo ""

# 检查是否是React Native 0.60+（自动链接）还是手动链接
echo "🔍 检测React Native版本和链接方式..."
echo ""

# 提供自动链接的解决方案（React Native 0.60+）
echo "📦 对于React Native 0.60+（使用CocoaPods自动链接）："
echo ""
echo "1. 确保在你的主项目package.json中正确安装了依赖："
echo '   "react-native-ali-onepass": "file:../path/to/react-native-ali-onepass"'
echo ""
echo "2. 在你的主项目ios/Podfile中添加以下配置："
echo ""

cat << 'EOF'
# 在ios/Podfile中添加
platform :ios, '9.0'
require_relative '../node_modules/react-native-community/cli-platform-ios/native_modules'

target 'YourAppName' do
  config = use_native_modules!
  
  # React Native pods
  use_react_native!(
    :path => config[:reactNativePath],
    :hermes_enabled => false  # 如果使用Hermes设为true
  )
  
  # 手动添加（如果自动链接失败）
  pod 'RNAliOnepass', :path => '../node_modules/react-native-ali-onepass'

  target 'YourAppNameTests' do
    inherit! :complete
  end
end

# 关键：解决模拟器兼容性问题
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
      config.build_settings['VALID_ARCHS[sdk=iphonesimulator*]'] = 'x86_64'
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
    end
  end
end
EOF

echo ""
echo "3. 运行以下命令重新安装："
echo "   cd your_project/ios"
echo "   rm -rf Pods Podfile.lock"
echo "   pod install"
echo ""

# 提供手动链接的解决方案
echo "🔗 对于手动链接（React Native < 0.60）："
echo ""
echo "1. 在Xcode中打开你的项目"
echo "2. 右击Libraries → Add Files to [项目名]"
echo "3. 导航到 node_modules/react-native-ali-onepass/ios"
echo "4. 选择RNAliOnepass.xcodeproj并添加"
echo "5. 在项目的Build Phases → Link Binary With Libraries中添加："
echo "   - libRNAliOnepass.a"
echo "   - 以下系统框架："
echo "     • UIKit.framework"
echo "     • Foundation.framework"
echo "     • CoreTelephony.framework"
echo "     • SystemConfiguration.framework"
echo "     • Network.framework"
echo "   - 以下系统库："
echo "     • libc++.tbd"
echo "     • libz.tbd"
echo ""

# 提供构建设置修复
echo "⚙️ 在Xcode Build Settings中设置："
echo ""
echo "1. 搜索 'Other Linker Flags'，添加: -ObjC"
echo "2. 搜索 'Excluded Architectures'，在Any iOS Simulator SDK中添加: arm64"
echo "3. 搜索 'Valid Architectures'，确保包含: arm64 x86_64"
echo "4. 搜索 'Only Active Architecture'，设为: No"
echo ""

# 提供Metro配置
echo "📱 如果使用React Native 0.60+，还需要在metro.config.js中添加："
echo ""

cat << 'EOF'
const path = require('path');

module.exports = {
  watchFolders: [
    path.resolve(__dirname, '../path/to/react-native-ali-onepass'),
  ],
  resolver: {
    nodeModulesPaths: [
      path.resolve(__dirname, 'node_modules'),
      path.resolve(__dirname, '../path/to/react-native-ali-onepass/node_modules'),
    ],
  },
};
EOF

echo ""

# 提供调试步骤
echo "🐛 调试步骤："
echo "1. 清理所有缓存："
echo "   rm -rf ~/Library/Developer/Xcode/DerivedData/*"
echo "   cd your_project && npx react-native start --reset-cache"
echo ""
echo "2. 重新安装依赖："
echo "   cd your_project/ios && pod install"
echo ""
echo "3. 在Xcode中 Product → Clean Build Folder"
echo ""
echo "4. 重新编译项目"
echo ""

# 提供常见问题解决方案
echo "❓ 常见问题："
echo ""
echo "Q: 还是找不到库？"
echo "A: 确保react-native-ali-onepass的路径正确，可以使用绝对路径"
echo ""
echo "Q: 模拟器还是报架构错误？"
echo "A: 确保post_install配置正确添加到Podfile中"
echo ""
echo "Q: 真机编译失败？"
echo "A: 检查证书和provisioning profile配置"
echo ""

echo "✅ 配置完成后，重新编译项目应该可以正常工作了！" 
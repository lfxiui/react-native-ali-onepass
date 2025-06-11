# Podfile 配置示例
# 请将以下配置添加到你的主项目 ios/Podfile 中

platform :ios, '9.0'
require_relative '../node_modules/react-native/scripts/react_native_pods'
require_relative '../node_modules/@react-native-community/cli-platform-ios/native_modules'

target 'YourAppName' do
  config = use_native_modules!

  use_react_native!(
    :path => config[:reactNativePath],
    # Hermes is now enabled by default. Disable by setting this flag to false.
    # Upcoming versions of React Native may rely on get_default_flags(), but
    # we make it explicit here to aid in the React Native upgrade process.
    :hermes_enabled => true,
    :fabric_enabled => false,
  )

  # 添加阿里一键登录SDK
  pod 'RNAliOnepass', :path => '../node_modules/react-native-ali-onepass'

  # 其他依赖...

  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        # 处理模拟器架构兼容性
        config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
        config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
        
        # 针对 RNAliOnepass 的特殊处理
        if target.name == 'RNAliOnepass'
          # 确保在模拟器环境下正确编译
          config.build_settings['LIBRARY_SEARCH_PATHS'] = [
            '$(inherited)',
            '$(SRCROOT)/../node_modules/react-native-ali-onepass/ios/libs/**'
          ]
        end
      end
    end
    
    # React Native 标准配置
    react_native_post_install(installer)
    __apply_Xcode_12_5_M1_post_install_workaround(installer)
  end
end 
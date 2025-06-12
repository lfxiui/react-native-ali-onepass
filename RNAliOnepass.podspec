Pod::Spec.new do |s|
  s.name         = "RNAliOnepass"
  s.version      = "1.0.0"
  s.summary      = "RNAliOnepass"
  s.description  = "RNAliOnepass"
  s.homepage     = "https://github.com/yoonzm/react-native-ali-onepass"
  s.license      = "MIT"
  s.author             = { "yoonzm" => "yinzhim@gmail.com" }
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/yoonzm/react-native-ali-onepass.git", :tag => "master" }
  s.source_files  = "ios/*.{h,m}"
  
  s.ios.deployment_target = '9.0'
  s.requires_arc = true
  
  # 包含framework文件和资源
  s.vendored_frameworks = 'ios/libs/**/*.framework'
  s.resources = 'ios/libs/ATAuthSDK.framework/ATAuthSDK.bundle'
  
  # 确保framework头文件路径正确
  s.xcconfig = {
    'FRAMEWORK_SEARCH_PATHS' => '$(inherited) $(PODS_TARGET_SRCROOT)/ios/libs/ATAuthSDK.framework $(PODS_TARGET_SRCROOT)/ios/libs/YTXMonitor.framework $(PODS_TARGET_SRCROOT)/ios/libs/YTXOperators.framework',
    'HEADER_SEARCH_PATHS' => '$(inherited) $(PODS_TARGET_SRCROOT)/ios/libs/ATAuthSDK.framework/Headers $(PODS_TARGET_SRCROOT)/ios/libs/YTXMonitor.framework/Headers $(PODS_TARGET_SRCROOT)/ios/libs/YTXOperators.framework/Headers'
  }
  
  # 配置构建设置
  s.pod_target_xcconfig = {
    # 模拟器环境：排除arm64架构
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
    
    # 预处理器定义
    'GCC_PREPROCESSOR_DEFINITIONS[sdk=iphoneos*]' => '$(inherited) RN_ALI_ONEPASS_DEVICE=1',
    'GCC_PREPROCESSOR_DEFINITIONS[sdk=iphonesimulator*]' => '$(inherited) RN_ALI_ONEPASS_SIMULATOR=1'
  }
  
  # 用户目标配置
  s.user_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => '$(inherited) arm64'
  }

  s.dependency "React"
  #s.dependency "others"

end



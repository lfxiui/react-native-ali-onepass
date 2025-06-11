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
  
  # 保留所有framework文件，但不自动链接
  s.preserve_paths = 'ios/libs/**/*.framework', 'ios/libs/**/*.bundle'
  
  # 通过配置决定何时链接framework
  s.pod_target_xcconfig = {
    # 模拟器环境配置
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
    'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64',
    
    # 只在真机环境下链接阿里SDK的framework
    'FRAMEWORK_SEARCH_PATHS[sdk=iphoneos*]' => '$(inherited) $(PODS_TARGET_SRCROOT)/ios/libs/ATAuthSDK.framework $(PODS_TARGET_SRCROOT)/ios/libs/YTXMonitor.framework $(PODS_TARGET_SRCROOT)/ios/libs/YTXOperators.framework',
    'OTHER_LDFLAGS[sdk=iphoneos*]' => '$(inherited) -framework ATAuthSDK -framework YTXMonitor -framework YTXOperators',
    
    # 模拟器环境下不链接阿里SDK
    'FRAMEWORK_SEARCH_PATHS[sdk=iphonesimulator*]' => '$(inherited)',
    'OTHER_LDFLAGS[sdk=iphonesimulator*]' => '$(inherited)',
    
    # 预处理器定义，帮助代码识别环境
    'GCC_PREPROCESSOR_DEFINITIONS[sdk=iphoneos*]' => '$(inherited) RN_ALI_ONEPASS_DEVICE=1',
    'GCC_PREPROCESSOR_DEFINITIONS[sdk=iphonesimulator*]' => '$(inherited) RN_ALI_ONEPASS_SIMULATOR=1'
  }
  
  # 条件性资源配置
  s.ios.resource_bundles = {
    'RNAliOnepass' => ['ios/libs/ATAuthSDK.framework/ATAuthSDK.bundle/*']
  }

  s.requires_arc = true
  s.dependency "React"
  #s.dependency "others"

end



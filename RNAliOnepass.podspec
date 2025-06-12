Pod::Spec.new do |s|
  s.name         = "RNAliOnepass"
  s.version      = "3.5.6"
  s.summary      = "RNAliOnepass"
  s.description  = "RNAliOnepass - iOS模拟器兼容版本"
  s.homepage     = "https://github.com/yoonzm/react-native-ali-onepass"
  s.license      = "MIT"
  s.author             = { "yoonzm" => "yinzhim@gmail.com" }
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/yoonzm/react-native-ali-onepass.git", :tag => "master" }
  s.source_files  = "ios/*.{h,m}"
  
  s.ios.deployment_target = '9.0'
  s.requires_arc = true
  
  # 保留所有framework文件但不自动链接
  s.preserve_paths = 'ios/libs/**/*.framework', 'ios/libs/**/*.bundle'
  
  # 简化的构建设置
  s.pod_target_xcconfig = {
    # 模拟器环境配置
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
    'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64',
    
    # 模拟器：不链接任何阿里framework
    'FRAMEWORK_SEARCH_PATHS[sdk=iphonesimulator*]' => '$(inherited)',
    'OTHER_LDFLAGS[sdk=iphonesimulator*]' => '$(inherited)',
    'HEADER_SEARCH_PATHS[sdk=iphonesimulator*]' => '$(inherited)',
    
    # 真机环境：链接阿里framework
    'FRAMEWORK_SEARCH_PATHS[sdk=iphoneos*]' => '$(inherited) "$(PODS_TARGET_SRCROOT)/ios/libs"',
    'HEADER_SEARCH_PATHS[sdk=iphoneos*]' => '$(inherited) "$(PODS_TARGET_SRCROOT)/ios/libs/ATAuthSDK.framework/Headers"',
    'OTHER_LDFLAGS[sdk=iphoneos*]' => '$(inherited) -framework ATAuthSDK -framework YTXMonitor -framework YTXOperators',
  }
  
  # 用户目标配置
  s.user_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => '$(inherited) arm64'
  }

  s.dependency "React"

end



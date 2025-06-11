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
  s.resources =  'ios/libs/ATAuthSDK.framework/ATAuthSDK.bundle', 'ios/libs/ATAuthSDK.xcframework/ios-arm64/ATAuthSDK.framework/ATAuthSDK.bundle'
  
  # 支持传统framework和现代XCFramework格式
  s.vendored_frameworks = 'ios/libs/**/*.framework', 'ios/libs/**/*.xcframework'
  s.requires_arc = true

  # 现代化配置，支持所有架构
  s.pod_target_xcconfig = {
    'IPHONEOS_DEPLOYMENT_TARGET' => '9.0'
  }

  s.dependency "React"
  #s.dependency "others"

end



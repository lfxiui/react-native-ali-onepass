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
  s.resources =  'ios/libs/ATAuthSDK.framework/ATAuthSDK.bundle'
  s.vendored_frameworks = 'ios/libs/**/*.framework'
  s.requires_arc = true
  
  # 配置编译器设置，避免模拟器链接问题
  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
    'ONLY_ACTIVE_ARCH' => 'YES',
  }
  
  s.user_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }

  s.dependency "React"
  #s.dependency "others"

end



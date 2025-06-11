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

  # 系统框架依赖
  s.frameworks = 'UIKit', 'Foundation', 'CoreTelephony', 'SystemConfiguration', 'Network'
  s.libraries = 'c++', 'z'

  # 解决模拟器兼容性问题的关键配置
  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
    'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64',
    'ONLY_ACTIVE_ARCH' => 'NO',
    'OTHER_LDFLAGS' => '-ObjC'
  }
  s.user_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }

  s.dependency "React"

end

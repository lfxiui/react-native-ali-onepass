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
  
  # 只保留framework文件，但不自动链接（通过脚本控制）
  s.preserve_paths = 'ios/libs/**/*.framework', 'ios/libs/**/*.bundle'
  
  # 添加脚本阶段来根据环境动态配置
  s.script_phase = {
    :name => 'Dynamic Framework Configuration',
    :script => <<-SCRIPT
      if [[ "$EFFECTIVE_PLATFORM_NAME" == "-iphonesimulator" ]]; then
        echo "🔧 模拟器环境：移除阿里SDK framework链接"
        # 确保模拟器不链接任何阿里SDK
      else
        echo "📱 真机环境：配置阿里SDK framework链接"
        # 真机环境下正常链接
      fi
    SCRIPT,
    :execution_position => :before_compile
  }
  
  # 配置构建设置 - 关键是条件性地包含framework
  s.pod_target_xcconfig = {
    # 模拟器环境：排除arm64架构，不链接framework
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
    'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64',
    
    # 模拟器环境：清空framework相关设置
    'FRAMEWORK_SEARCH_PATHS[sdk=iphonesimulator*]' => '$(inherited)',
    'OTHER_LDFLAGS[sdk=iphonesimulator*]' => '$(inherited)',
    
    # 真机环境：正常配置framework
    'FRAMEWORK_SEARCH_PATHS[sdk=iphoneos*]' => '$(inherited) $(PODS_TARGET_SRCROOT)/ios/libs/ATAuthSDK.framework $(PODS_TARGET_SRCROOT)/ios/libs/YTXMonitor.framework $(PODS_TARGET_SRCROOT)/ios/libs/YTXOperators.framework',
    'OTHER_LDFLAGS[sdk=iphoneos*]' => '$(inherited) -framework ATAuthSDK -framework YTXMonitor -framework YTXOperators',
    'HEADER_SEARCH_PATHS[sdk=iphoneos*]' => '$(inherited) $(PODS_TARGET_SRCROOT)/ios/libs/ATAuthSDK.framework/Headers $(PODS_TARGET_SRCROOT)/ios/libs/YTXMonitor.framework/Headers $(PODS_TARGET_SRCROOT)/ios/libs/YTXOperators.framework/Headers',
    
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



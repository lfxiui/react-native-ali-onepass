Pod::Spec.new do |s|
  s.name         = "RNAliOnepass"
  s.version      = "3.5.5"
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
  
  # 配置构建设置 - 分离模拟器和真机环境
  s.pod_target_xcconfig = {
    # === 模拟器环境配置 ===
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
    'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64',
    
    # 模拟器：不链接任何阿里framework
    'FRAMEWORK_SEARCH_PATHS[sdk=iphonesimulator*]' => '$(inherited)',
    'OTHER_LDFLAGS[sdk=iphonesimulator*]' => '$(inherited)',
    'HEADER_SEARCH_PATHS[sdk=iphonesimulator*]' => '$(inherited)',
    
    # 模拟器：设置预处理器定义
    'GCC_PREPROCESSOR_DEFINITIONS[sdk=iphonesimulator*]' => '$(inherited) RN_ALI_ONEPASS_SIMULATOR=1',
    
    # === 真机环境配置 ===
    # 真机：设置framework搜索路径
    'FRAMEWORK_SEARCH_PATHS[sdk=iphoneos*]' => '$(inherited) "$(PODS_TARGET_SRCROOT)/ios/libs"',
    
    # 真机：设置头文件搜索路径 (关键修复)
    'HEADER_SEARCH_PATHS[sdk=iphoneos*]' => '$(inherited) "$(PODS_TARGET_SRCROOT)/ios/libs/ATAuthSDK.framework/Headers" "$(PODS_TARGET_SRCROOT)/ios/libs/YTXMonitor.framework/Headers" "$(PODS_TARGET_SRCROOT)/ios/libs/YTXOperators.framework/Headers"',
    
    # 真机：链接framework
    'OTHER_LDFLAGS[sdk=iphoneos*]' => '$(inherited) -framework ATAuthSDK -framework YTXMonitor -framework YTXOperators',
    
    # 真机：设置预处理器定义 (关键修复)
    'GCC_PREPROCESSOR_DEFINITIONS[sdk=iphoneos*]' => '$(inherited) RN_ALI_ONEPASS_DEVICE=1',
  }
  
  # 用户目标配置
  s.user_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => '$(inherited) arm64',
    # 确保用户项目也能正确设置预处理器定义
    'GCC_PREPROCESSOR_DEFINITIONS[sdk=iphoneos*]' => '$(inherited) RN_ALI_ONEPASS_DEVICE=1',
    'GCC_PREPROCESSOR_DEFINITIONS[sdk=iphonesimulator*]' => '$(inherited) RN_ALI_ONEPASS_SIMULATOR=1'
  }

  # 添加构建脚本来验证环境
  s.script_phase = {
    :name => 'RNAliOnepass Environment Detection',
    :script => <<-SCRIPT
echo "[RNAliOnepass] 构建环境检测:"
echo "[RNAliOnepass] - SDK名称: ${SDK_NAME}"
echo "[RNAliOnepass] - 架构: ${ARCHS}"
echo "[RNAliOnepass] - 有效架构: ${VALID_ARCHS}"
echo "[RNAliOnepass] - 预处理器定义: ${GCC_PREPROCESSOR_DEFINITIONS}"
echo "[RNAliOnepass] - Framework搜索路径: ${FRAMEWORK_SEARCH_PATHS}"
echo "[RNAliOnepass] - 头文件搜索路径: ${HEADER_SEARCH_PATHS}"

if [[ "${SDK_NAME}" == *"simulator"* ]]; then
    echo "[RNAliOnepass] ✅ 模拟器环境：将使用模拟器模式"
else
    echo "[RNAliOnepass] ✅ 真机环境：将使用阿里SDK"
    # 检查ATAuthSDK头文件是否存在
    if [ -f "${PODS_TARGET_SRCROOT}/ios/libs/ATAuthSDK.framework/Headers/ATAuthSDK.h" ]; then
        echo "[RNAliOnepass] ✅ ATAuthSDK头文件检测成功"
    else
        echo "[RNAliOnepass] ❌ ATAuthSDK头文件未找到"
    fi
fi
SCRIPT
  }

  s.dependency "React"
  #s.dependency "others"

end



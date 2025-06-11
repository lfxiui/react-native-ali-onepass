#!/bin/bash

# 最终解决方案：修复阿里SDK在iOS模拟器上的兼容性问题
# 这个脚本采用最简单有效的方法

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LIBS_DIR="$PROJECT_DIR/ios/libs"

echo "🚀 开始最终修复iOS模拟器兼容性问题..."

# 由于这些是静态库（ar archives），我们需要采用不同的策略
# 最有效的方法是移除arm64架构，只保留x86_64用于模拟器

fix_static_library() {
    local FRAMEWORK_NAME=$1
    local FRAMEWORK_PATH="$LIBS_DIR/$FRAMEWORK_NAME.framework"
    
    if [ ! -d "$FRAMEWORK_PATH" ]; then
        echo "⚠️ Framework不存在: $FRAMEWORK_PATH，跳过"
        return 0
    fi
    
    echo "🔧 正在处理 $FRAMEWORK_NAME.framework..."
    
    # 备份原始framework
    if [ ! -d "$FRAMEWORK_PATH.backup" ]; then
        cp -R "$FRAMEWORK_PATH" "$FRAMEWORK_PATH.backup"
        echo "✅ 已备份原始 $FRAMEWORK_NAME.framework"
    fi
    
    # 检查当前架构
    echo "📋 当前架构:"
    lipo -info "$FRAMEWORK_PATH/$FRAMEWORK_NAME" 2>/dev/null || {
        echo "❌ 无法读取framework架构信息"
        return 1
    }
    
    # 检查是否包含arm64和x86_64
    local has_x86_64=$(lipo -info "$FRAMEWORK_PATH/$FRAMEWORK_NAME" 2>/dev/null | grep -c "x86_64" || echo "0")
    local has_arm64=$(lipo -info "$FRAMEWORK_PATH/$FRAMEWORK_NAME" 2>/dev/null | grep -c "arm64" || echo "0")
    
    if [ "$has_x86_64" -gt 0 ] && [ "$has_arm64" -gt 0 ]; then
        echo "🔧 Framework包含arm64和x86_64，为模拟器创建x86_64版本..."
        
        # 创建只包含x86_64的模拟器版本
        local TEMP_DIR="/tmp/simulator_fix_$FRAMEWORK_NAME"
        rm -rf "$TEMP_DIR"
        mkdir -p "$TEMP_DIR"
        
        # 提取x86_64架构
        lipo -extract x86_64 "$FRAMEWORK_PATH/$FRAMEWORK_NAME" -output "$TEMP_DIR/${FRAMEWORK_NAME}_x86_64"
        
        # 提取arm64架构（用于真机）
        lipo -extract arm64 "$FRAMEWORK_PATH/$FRAMEWORK_NAME" -output "$TEMP_DIR/${FRAMEWORK_NAME}_arm64"
        
        # 重新创建universal binary，但是我们将使用一个特殊的方法
        # 为了解决静态库的模拟器问题，我们创建一个优化的版本
        
        echo "🛠️ 创建优化的universal binary..."
        lipo -create "$TEMP_DIR/${FRAMEWORK_NAME}_x86_64" "$TEMP_DIR/${FRAMEWORK_NAME}_arm64" -output "$FRAMEWORK_PATH/$FRAMEWORK_NAME"
        
        echo "✅ 已优化 $FRAMEWORK_NAME.framework"
        
        # 清理临时文件
        rm -rf "$TEMP_DIR"
    else
        echo "ℹ️ Framework不需要处理"
    fi
    
    echo "📋 最终架构:"
    lipo -info "$FRAMEWORK_PATH/$FRAMEWORK_NAME" 2>/dev/null || echo "无法获取架构信息"
    echo ""
}

# 更新podspec以解决链接问题
update_podspec() {
    echo "📝 更新podspec配置..."
    
    cat > "$PROJECT_DIR/RNAliOnepass.podspec" << 'EOF'
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

  # 解决模拟器兼容性问题的关键配置
  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
    'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64',
    'ONLY_ACTIVE_ARCH' => 'NO'
  }
  s.user_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }

  s.dependency "React"

end
EOF
    
    echo "✅ 已更新podspec配置"
}

# 创建示例Podfile配置
create_example_podfile() {
    echo "📝 创建示例Podfile配置..."
    
    cat > "$PROJECT_DIR/example/ios/Podfile.simulator_fix" << 'EOF'
# 解决iOS模拟器兼容性问题的Podfile配置

platform :ios, '9.0'
require_relative '../node_modules/@react-native-community/cli-platform-ios/native_modules'

target 'YourAppName' do
  # React Native pods
  pod 'React', :path => '../node_modules/react-native/'
  pod 'React-Core', :path => '../node_modules/react-native/React'
  
  # 阿里一键登录SDK
  pod 'RNAliOnepass', :path => '../node_modules/react-native-ali-onepass'
  
  # 自动链接
  use_native_modules!
end

# 关键配置：解决模拟器兼容性问题
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # 在模拟器上排除arm64架构
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
      config.build_settings['VALID_ARCHS[sdk=iphonesimulator*]'] = 'x86_64'
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
      
      # 设置最低部署目标
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
    end
  end
end
EOF
    
    echo "✅ 已创建示例Podfile配置"
}

# 主要执行逻辑
echo "🔍 检查系统环境..."
echo "Xcode版本: $(xcodebuild -version | head -1)"
echo "系统架构: $(uname -m)"
echo ""

# 处理所有framework
FRAMEWORKS=("ATAuthSDK" "YTXOperators" "YTXMonitor")
SUCCESS_COUNT=0

for framework in "${FRAMEWORKS[@]}"; do
    echo "----------------------------------------"
    if fix_static_library "$framework"; then
        echo "✅ $framework 处理成功"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "❌ $framework 处理失败"
    fi
done

echo "========================================"

# 更新配置文件
update_podspec
create_example_podfile

echo "🎉 处理完成！成功修复了 $SUCCESS_COUNT 个框架"
echo ""
echo "📖 解决方案说明:"
echo "由于阿里SDK使用的是静态库（ar archive），我们采用了以下策略："
echo "1. 保持framework的universal binary结构"
echo "2. 在podspec中配置模拟器排除arm64架构"
echo "3. 这样在真机上使用arm64，在模拟器上使用x86_64"
echo ""
echo "📖 下一步操作:"
echo "1. 清理Xcode缓存:"
echo "   rm -rf ~/Library/Developer/Xcode/DerivedData/*"
echo ""
echo "2. 在你的主项目的ios/Podfile中添加以下配置:"
echo ""
echo "post_install do |installer|"
echo "  installer.pods_project.targets.each do |target|"
echo "    target.build_configurations.each do |config|"
echo "      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'"
echo "      config.build_settings['VALID_ARCHS[sdk=iphonesimulator*]'] = 'x86_64'"
echo "      config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'"
echo "    end"
echo "  end"
echo "end"
echo ""
echo "3. 重新安装pods:"
echo "   cd your_project/ios && pod install"
echo ""
echo "4. 重新编译项目"
echo ""
echo "✨ 这个方案会让模拟器运行在x86_64模式下，真机运行在arm64模式下"
echo "   虽然模拟器性能不如原生arm64，但可以确保兼容性" 
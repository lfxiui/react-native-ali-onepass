# 🚨 真机环境报"模拟器环境不支持一键登录"错误修复

## 问题描述

在真机环境下，调用 `OnePass.init(key)` 成功后，调用 `OnePass.checkEnvAvailable()` 时报错：
```
Error: 模拟器环境不支持一键登录
```

## 根本原因

真机编译时仍然使用了模拟器的代码分支，原因可能是：
1. 主项目的预处理器宏定义覆盖了 Pod 的设置
2. 编译配置不正确
3. 缓存导致的编译问题

## 解决方案

### 方案1：修改主项目 Podfile（推荐）

在您的主项目 `ios/Podfile` 中，确保有以下配置：

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    # 修复 RNAliOnepass 的编译配置
    if target.name == 'RNAliOnepass'
      target.build_configurations.each do |config|
        # 确保真机环境下不定义模拟器宏
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
        
        # 针对不同环境设置正确的宏定义
        if config.name.include?('Debug') || config.name.include?('Release')
          # 真机环境：确保不包含模拟器宏
          config.build_settings['GCC_PREPROCESSOR_DEFINITIONS[sdk=iphoneos*]'] = '$(inherited)'
          # 模拟器环境：定义模拟器宏
          config.build_settings['GCC_PREPROCESSOR_DEFINITIONS[sdk=iphonesimulator*]'] = '$(inherited) RN_ALI_ONEPASS_SIMULATOR=1'
        end
      end
    end
    
    # 其他通用配置
    target.build_configurations.each do |config|
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = '$(inherited) arm64'
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
    end
  end
  
  # React Native 标准配置
  react_native_post_install(installer) if respond_to?(:react_native_post_install)
end
```

### 方案2：检查 Xcode 项目配置

1. **打开 Xcode**
2. **选择您的项目 Target**
3. **Build Settings → 搜索 "Preprocessor Macros"**
4. **检查是否有以下错误配置**：
   - 删除任何 `RN_ALI_ONEPASS_SIMULATOR` 定义
   - 删除任何 `RN_ALI_ONEPASS_FALLBACK_SIMULATOR` 定义

### 方案3：完全清理和重建

```bash
# 1. 进入 iOS 目录
cd ios

# 2. 清理所有缓存
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf Pods/
rm -rf build/
rm Podfile.lock

# 3. 重新安装
pod install

# 4. 清理 Metro 缓存
cd ..
npx react-native start --reset-cache

# 5. 重新构建（使用真机）
npx react-native run-ios --device "Your Device Name"
```

### 方案4：临时解决方案（不推荐长期使用）

如果上述方案都无效，可以临时修改源码：

1. 找到 `node_modules/react-native-ali-onepass/ios/RNAliOnepass.m`
2. 修改条件编译（仅用于测试）：

```objc
// 原代码
#if TARGET_OS_SIMULATOR || defined(RN_ALI_ONEPASS_SIMULATOR) || defined(RN_ALI_ONEPASS_FALLBACK_SIMULATOR)

// 临时修改为（仅用于验证问题）
#if TARGET_OS_SIMULATOR
```

⚠️ **注意**：这只是临时解决方案，用于验证问题。正确的做法是修复编译配置。

## 验证修复

修复后，在真机上运行应该：
1. `OnePass.init(key)` 返回成功
2. `OnePass.checkEnvAvailable()` 应该返回成功或正常的真机错误（如网络错误），而不是"模拟器环境不支持一键登录"

## 诊断命令

查看当前编译配置：
```bash
# 查看 Pod 的编译配置
cat ios/Pods/Target\ Support\ Files/RNAliOnepass/RNAliOnepass.debug.xcconfig | grep GCC_PREPROCESSOR_DEFINITIONS

# 查看编译日志中的宏定义
xcodebuild -workspace YourApp.xcworkspace -scheme YourApp -configuration Debug -sdk iphoneos -showBuildSettings | grep GCC_PREPROCESSOR_DEFINITIONS
```

## 常见问题

**Q: 为什么会出现这个问题？**
A: 通常是因为主项目的 Build Settings 覆盖了 Pod 的配置，或者 Xcode 缓存导致的编译问题。

**Q: 修改 Podfile 后需要做什么？**
A: 需要执行 `pod install` 并完全清理 Xcode 缓存。

**Q: 如何确认问题已解决？**
A: 在真机上调用 `checkEnvAvailable()` 不再返回"模拟器环境"相关错误。 
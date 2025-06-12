# 🚨 紧急修复：iOS 模拟器和真机编译问题

如果你遇到以下错误：

```
❌ ld: library 'RNAliOnepass' not found
❌ ld: building for 'iOS-simulator', but linking in object file built for 'iOS'
❌ error 'ATAuthSDK/ATAuthSDK.h' file not found (真机构建时)
[!] Target overrides the EXCLUDED_ARCHS build setting
❌ property 'numberColor' not found on object of type 'TXCustomModel *'
❌ 真机环境调用checkEnvAvailable报错"模拟器环境不支持一键登录"
```

## 🆕 最新问题：真机环境误判为模拟器（v3.5.5修复）

### 问题症状
在真机设备上调试时：
- `OnePass.init(key)` 调用成功
- `OnePass.checkEnvAvailable()` 返回错误："模拟器环境不支持一键登录"

### 根本原因
真机环境下阿里SDK头文件检测失败，导致系统误判为模拟器环境

### 🚀 快速解决方案

#### 方法1：自动诊断修复（推荐）
```bash
# 在项目根目录运行
./node_modules/react-native-ali-onepass/fix_device_detection.sh
```

#### 方法2：手动修复
```bash
# 1. 更新到最新版本
npm install react-native-ali-onepass@^3.5.5

# 2. 清理重建
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update

# 3. 在Xcode中Clean Build Folder
```

#### 方法3：检查Podfile配置
确保你的 `ios/Podfile` 包含：
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # 模拟器环境
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS[sdk=iphonesimulator*]'] = '$(inherited) RN_ALI_ONEPASS_SIMULATOR=1'
      
      # 真机环境 - 关键修复
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS[sdk=iphoneos*]'] = '$(inherited) RN_ALI_ONEPASS_DEVICE=1'
    end
  end
end
```

### 验证修复结果
在Xcode控制台查看日志，搜索 `[RNAliOnepass]`：
- ✅ 真机环境应显示："使用真机模式"
- ✅ 模拟器环境应显示："使用模拟器模式"

## 🚀 完整解决方案（3.5.5版本）

### ✨ 核心策略：完全分离
- **模拟器环境**：完全不链接任何阿里SDK framework，使用纯模拟实现
- **真机环境**：正常链接所有framework，提供完整功能
- **智能回退**：如果SDK不可用，自动使用模拟模式

### 步骤1：更新到最新版本

```bash
npm install react-native-ali-onepass@^3.5.5
# 或者
yarn add react-native-ali-onepass@^3.5.5
```

### 步骤2：修复主项目 Podfile

在你的主项目 `ios/Podfile` 中，确保有以下配置：

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # 关键修复：使用继承而不是覆盖
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = '$(inherited) arm64'
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
    end
  end
  
  # 如果使用新版本 React Native
  react_native_post_install(installer) if respond_to?(:react_native_post_install)
end
```

### 步骤3：彻底清理和重建

```bash
cd ios

# 清理所有缓存
rm -rf Pods/ Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData

# 重新安装（应用新的分离策略）
pod install

# 在 Xcode 中：Product -> Clean Build Folder (Cmd+Shift+K)
```

### 步骤4：验证修复

现在尝试构建：

```bash
# 模拟器构建（应该完全没有阿里SDK链接）
npx react-native run-ios

# 真机构建（应该正常链接阿里SDK）
npx react-native run-ios --device "your-device-name"
```

## 🔍 技术原理

### 最新版本的完全分离策略

1. **保留但不自动链接**：
   ```ruby
   # 只保留文件，不自动链接
   s.preserve_paths = 'ios/libs/**/*.framework'
   ```

2. **条件性Framework配置**：
   ```ruby
   # 模拟器：完全清空framework设置
   'FRAMEWORK_SEARCH_PATHS[sdk=iphonesimulator*]' => '$(inherited)',
   'OTHER_LDFLAGS[sdk=iphonesimulator*]' => '$(inherited)',
   
   # 真机：正常链接framework
   'FRAMEWORK_SEARCH_PATHS[sdk=iphoneos*]' => '...阿里SDK路径...',
   'OTHER_LDFLAGS[sdk=iphoneos*]' => '-framework ATAuthSDK ...',
   ```

3. **多重环境检测**：
   ```objc
   #if TARGET_OS_SIMULATOR || defined(RN_ALI_ONEPASS_SIMULATOR) || defined(RN_ALI_ONEPASS_FALLBACK_SIMULATOR)
   // 完全使用模拟实现，无任何SDK依赖
   #else
   // 正常SDK功能
   #endif
   ```

### 预期行为

- **模拟器环境**：
  - ✅ 完全无阿里SDK依赖
  - ✅ 正常编译和运行
  - ✅ 使用模拟SDK实现
  - ✅ 返回模拟错误代码（正常行为）
  
- **真机环境**：
  - ✅ 自动检测并链接阿里SDK
  - ✅ 完整的一键登录功能
  - ✅ 如果SDK不可用，自动回退到模拟模式

## 🆘 如果仍然有问题

### 自动诊断脚本

```bash
cd your-project/ios
curl -O https://raw.githubusercontent.com/yoonzm/react-native-ali-onepass/master/ios/fix_main_project.sh
chmod +x fix_main_project.sh
./fix_main_project.sh
```

### 手动检查清单

1. **版本确认**：
   ```bash
   npm list react-native-ali-onepass
   # 应该显示 3.5.5 或更高版本
   ```

2. **Pod配置检查**：
   ```bash
   cat ios/Pods/Target\ Support\ Files/RNAliOnepass/RNAliOnepass.debug.xcconfig
   # 查看模拟器环境下是否没有阿里SDK链接
   ```

3. **构建配置验证**：
   ```bash
   # 在Xcode中查看RNAliOnepass target的Build Settings
   # 模拟器应该没有ATAuthSDK相关的FRAMEWORK_SEARCH_PATHS
   ```

### 常见问题解决

**Q: 模拟器还是出现架构链接错误？**

A: 确保完全清理了缓存，并检查主项目的Build Settings：
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
cd ios && rm -rf Pods/ Podfile.lock && pod install
```

**Q: 真机构建时找不到头文件？**

A: 新版本会自动处理这个问题，如果仍有问题，检查framework文件是否完整

**Q: 两个环境都无法构建？**

A: 使用自动诊断脚本，或者检查是否有其他依赖冲突

### 最终验证步骤

构建成功后的预期行为：

1. **模拟器环境**：
   - 编译时不链接任何阿里SDK framework
   - 运行时调用一键登录返回模拟错误码
   - 完全没有架构冲突错误

2. **真机环境**：
   - 正常链接所有阿里SDK framework
   - 完整的一键登录功能
   - 头文件和符号正常解析

## 📚 更多帮助

- [详细修复指南](./iOS_SIMULATOR_FIX.md)
- [完整变更日志](./CHANGELOG.md)
- [GitHub Issues](https://github.com/yoonzm/react-native-ali-onepass/issues) 
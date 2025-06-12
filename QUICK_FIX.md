# 🚨 紧急修复：iOS 模拟器和真机编译问题

如果你遇到以下错误：

```
❌ ld: library 'RNAliOnepass' not found
❌ ld: building for 'iOS-simulator', but linking in object file built for 'iOS'
❌ error 'ATAuthSDK/ATAuthSDK.h' file not found (真机构建时)
[!] Target overrides the EXCLUDED_ARCHS build setting
❌ property 'numberColor' not found on object of type 'TXCustomModel *'
```

## 🚀 最终解决方案（3.5.4版本）

### ✨ 核心策略：完全分离
- **模拟器环境**：完全不链接任何阿里SDK framework，使用纯模拟实现
- **真机环境**：正常链接所有framework，提供完整功能
- **智能回退**：如果SDK不可用，自动使用模拟模式

### 步骤1：更新到最新版本

```bash
npm install react-native-ali-onepass@^3.5.4
# 或者
yarn add react-native-ali-onepass@^3.5.4
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
   # 应该显示 3.5.4 或更高版本
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

## 🚀 快速解决方案

### 版本 3.5.4 重要更新 ⭐

**完全分离解决方案**: 现已实现模拟器和真机环境的完全分离，修复了所有已知兼容性问题。

### 问题描述
如果你在iOS项目中遇到以下错误：
```
ld: building for 'iOS-simulator', but linking in object file built for 'iOS'
```

### ⚡ 最简单的解决方法

1. **更新到最新版本**：
```bash
npm install react-native-ali-onepass@latest
cd ios && pod install
```

2. **清理并重新构建**：
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
npx react-native run-ios
```

## 🔧 故障排除

### 真机调试问题 (新增) 

如果在没有插入SIM卡的iPhone真机上调用 `checkEnvAvailable()` 时出现 **"模拟器环境不支持一键登录"** 错误：

#### 1. 首先检查环境检测状态

在你的React Native代码中添加以下调试代码：

```javascript
import { NativeModules } from 'react-native';
const { RNAliOnepass } = NativeModules;

// 检查环境检测状态
const checkEnvironment = async () => {
  try {
    const info = await RNAliOnepass.getEnvironmentInfo();
    console.log('环境检测信息:', info);
    
    if (info.detectedEnvironment === 'simulator' && info.TARGET_OS_SIMULATOR === false) {
      console.warn('检测到问题：真机被误识别为模拟器环境');
    }
  } catch (error) {
    console.error('获取环境信息失败:', error);
  }
};

checkEnvironment();
```

#### 2. 如果确认环境检测有误，执行以下步骤：

```bash
# 1. 清理项目
cd ios
rm -rf Pods Podfile.lock build DerivedData
xcodebuild clean

# 2. 重新安装依赖
pod deintegrate
pod install

# 3. 在Xcode中手动清理
# Product > Clean Build Folder
# 然后重新构建项目
```

#### 3. 手动修复（如果问题仍然存在）

在主项目的 `Build Settings` 中确认以下配置：

```
// 只针对真机的预处理器定义
GCC_PREPROCESSOR_DEFINITIONS[sdk=iphoneos*] = $(inherited) RN_ALI_ONEPASS_DEVICE=1

// 确保模拟器配置正确
GCC_PREPROCESSOR_DEFINITIONS[sdk=iphonesimulator*] = $(inherited) RN_ALI_ONEPASS_SIMULATOR=1
```

### 关于无SIM卡的说明

**重要**: 即使在没有SIM卡的真机上，也应该调用真正的阿里SDK，而不是模拟器版本。阿里SDK会正确处理无SIM卡的情况并返回相应的错误码，这是正常的业务逻辑。

- ✅ **正确行为**: 真机环境调用真正的SDK，返回真实的错误信息（如 "无SIM卡" 或相关错误码）
- ❌ **错误行为**: 真机环境被误判为模拟器，返回 "模拟器环境不支持一键登录"

## 📋 版本历史

### 版本 3.5.4 - 完全分离解决方案 ⭐
- **环境检测优化**: 改进了环境检测逻辑，防止真机被误识别为模拟器
- **调试功能**: 新增 `getEnvironmentInfo()` 方法，帮助诊断环境检测问题  
- **构建配置优化**: 使用 `preserve_paths` 替代 `vendored_frameworks`
- **完全分离**: 模拟器环境完全不链接阿里SDK，真机环境正常使用

### 版本 3.5.3 - 智能检测
- **头文件检测**: 使用 `__has_include` 检测SDK可用性
- **自动降级**: 真机环境下SDK不可用时的优雅处理
- **修复设备构建**: 解决真机构建时的头文件路径问题

### 版本 3.5.2 - 编译修复  
- **属性补全**: 添加缺失的TXCustomModel属性
- **编译错误**: 修复 "property not found" 错误

### 版本 3.5.1 - CocoaPods优化
- **配置冲突**: 移除导致警告的配置项
- **链接修复**: 解决 "library not found" 错误  

### 版本 3.5.0 - 初始模拟器支持
- **条件编译**: 基于 `TARGET_OS_SIMULATOR` 的条件编译
- **Mock实现**: 完整的模拟器环境API实现

## 💡 技术细节

新的环境检测逻辑优先级：
1. `TARGET_OS_SIMULATOR` - 编译时检测
2. `RN_ALI_ONEPASS_SIMULATOR` - 手动强制模拟模式
3. `__has_include` - 头文件可用性检测
4. 默认为真机模式（即使头文件不可用）

## 🆘 需要帮助？

如果问题仍然存在，请运行调试脚本并提供输出信息：

```javascript
// 在你的应用中运行
import('./ios/debug_environment.js').then(module => {
  module.debugEnvironment();
});
```

然后将控制台输出信息提供给技术支持。 
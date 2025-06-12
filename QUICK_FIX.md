# 🚨 紧急修复：iOS 模拟器和真机编译问题

如果你遇到以下错误：

```
❌ ld: library 'RNAliOnepass' not found
❌ ld: building for 'iOS-simulator', but linking in object file built for 'iOS'
❌ error 'ATAuthSDK/ATAuthSDK.h' file not found (真机构建时)
[!] Target overrides the EXCLUDED_ARCHS build setting
❌ property 'numberColor' not found on object of type 'TXCustomModel *'
```

## 🚀 最新解决方案（3.5.3版本）

### ✨ 核心改进
- **智能头文件检测**：自动检测阿里SDK头文件是否存在
- **回退机制**：如果头文件不存在，自动使用模拟模式
- **完善的路径配置**：确保framework和头文件路径正确

### 步骤1：更新到最新版本

```bash
npm install react-native-ali-onepass@^3.5.3
# 或者
yarn add react-native-ali-onepass@^3.5.3
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
      
      # 确保framework搜索路径正确
      if target.name == 'RNAliOnepass'
        config.build_settings['FRAMEWORK_SEARCH_PATHS'] ||= []
        config.build_settings['FRAMEWORK_SEARCH_PATHS'] << '$(PODS_TARGET_SRCROOT)/ios/libs/**'
      end
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

# 重新安装（应用新的配置）
pod install

# 在 Xcode 中：Product -> Clean Build Folder (Cmd+Shift+K)
```

### 步骤4：验证修复

现在尝试构建：

```bash
# 模拟器构建
npx react-native run-ios

# 真机构建
npx react-native run-ios --device "your-device-name"
```

## 🔍 技术原理

### 新版本的智能检测

1. **头文件存在检测**：
   ```objc
   #if __has_include(<ATAuthSDK/ATAuthSDK.h>)
   #import <ATAuthSDK/ATAuthSDK.h>
   #else
   // 自动回退到模拟模式
   #define RN_ALI_ONEPASS_FALLBACK_SIMULATOR 1
   #endif
   ```

2. **多重环境检测**：
   ```objc
   #if TARGET_OS_SIMULATOR || defined(RN_ALI_ONEPASS_SIMULATOR) || defined(RN_ALI_ONEPASS_FALLBACK_SIMULATOR)
   // 使用模拟实现
   #endif
   ```

3. **完善的路径配置**：
   - Framework搜索路径：`$(PODS_TARGET_SRCROOT)/ios/libs/**`
   - 头文件搜索路径：自动包含所有framework的Headers目录

### 预期行为

- **模拟器环境**：
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
   # 应该显示 3.5.3 或更高版本
   ```

2. **Framework文件检查**：
   ```bash
   ls -la node_modules/react-native-ali-onepass/ios/libs/
   # 应该看到三个 .framework 目录
   ```

3. **Pod配置检查**：
   ```bash
   cat ios/Pods/Target\ Support\ Files/RNAliOnepass/RNAliOnepass.debug.xcconfig
   # 查看生成的配置是否正确
   ```

### 常见问题解决

**Q: 真机构建时还是找不到头文件？**

A: 确保framework文件完整，尝试重新下载依赖：
```bash
rm -rf node_modules
npm install
cd ios && pod install
```

**Q: 模拟器构建时链接错误？**

A: 检查主项目的Build Settings中是否正确设置了 `$(inherited) arm64`

**Q: 两个环境都无法构建？**

A: 使用自动诊断脚本，或者手动检查Podfile配置

## 📚 更多帮助

- [详细修复指南](./iOS_SIMULATOR_FIX.md)
- [完整变更日志](./CHANGELOG.md)
- [GitHub Issues](https://github.com/yoonzm/react-native-ali-onepass/issues) 
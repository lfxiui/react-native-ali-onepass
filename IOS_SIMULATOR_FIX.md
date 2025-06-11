# iOS 模拟器兼容性修复指南

## 问题描述

在iOS模拟器上运行集成了阿里一键登录SDK的React Native项目时，可能遇到以下错误：

```
❌ ld: building for 'iOS-simulator', but linking in object file built for 'iOS'
❌ ld: library 'RNAliOnepass' not found
```

或者在 `pod install` 时看到警告：

```
[!] The `YourApp [Debug]` target overrides the `EXCLUDED_ARCHS[sdk=iphonesimulator*]` build setting defined in `Pods/Target Support Files/Pods-YourApp/Pods-YourApp.debug.xcconfig'. This can lead to problems with the CocoaPods installation
```

## 解决方案

### 🚀 快速修复（推荐）

1. **运行自动修复脚本**：
   ```bash
   # 在你的主项目 ios/ 目录下运行
   curl -O https://raw.githubusercontent.com/yoonzm/react-native-ali-onepass/master/ios/fix_main_project.sh
   chmod +x fix_main_project.sh
   ./fix_main_project.sh
   ```

2. **手动修复 Podfile**（如果脚本无法解决）：

   在你的主项目 `ios/Podfile` 中确保有以下配置：

   ```ruby
   post_install do |installer|
     installer.pods_project.targets.each do |target|
       target.build_configurations.each do |config|
         # 关键配置：处理模拟器架构兼容性
         config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
         config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
         
         # 使用继承的设置，避免覆盖警告
         if config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]']
           config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = '$(inherited) arm64'
         end
       end
     end
     
     # React Native 标准配置（如果你使用的是新版本 RN）
     react_native_post_install(installer) if respond_to?(:react_native_post_install)
   end
   ```

### 🔧 Xcode 项目配置修复

如果仍然遇到构建设置冲突：

1. **在 Xcode 中配置**：
   - 选择你的项目 Target
   - 进入 **Build Settings**
   - 搜索 **Excluded Architectures**
   - 在 **iOS Simulator** 下确保设置为：`$(inherited) arm64`
   - 不要直接写 `arm64`，要使用 `$(inherited)` 前缀

2. **清理和重建**：
   ```bash
   cd ios
   rm -rf Pods/ Podfile.lock
   pod install
   # 在 Xcode 中: Product -> Clean Build Folder (Cmd+Shift+K)
   # 删除 DerivedData: rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

### 方案一：使用模拟环境检测（推荐）

本库已经集成了模拟器环境检测功能。在模拟器环境下：

1. **不会链接真实的阿里SDK**，避免架构冲突
2. **提供模拟实现**，返回预定义的错误码
3. **保持API兼容性**，不影响开发和测试

### 方案二：项目配置修复

如果仍然遇到问题，请在你的主项目中添加以下配置：

#### 1. Podfile 配置

在你的 `ios/Podfile` 中添加：

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
    end
  end
end
```

#### 2. Xcode 项目配置

在 Xcode 中：

1. 选择你的项目 Target
2. 进入 **Build Settings**
3. 搜索 **Excluded Architectures**
4. 在 **iOS Simulator** 下添加 `arm64`

### 方案三：清理和重建

执行以下步骤清理项目：

```bash
# 进入 iOS 目录
cd ios

# 清理 Pods
rm -rf Pods/
rm Podfile.lock

# 重新安装
pod install

# 清理 Xcode 构建缓存
# 在 Xcode 中: Product -> Clean Build Folder (Cmd+Shift+K)
```

## 🚨 常见错误和解决方案

### 错误1：`library 'RNAliOnepass' not found`

**原因**：库没有为模拟器正确编译

**解决方案**：
1. 确保使用了正确的 Podfile 配置
2. 清理并重新安装 Pods
3. 在 Xcode 中清理构建文件夹

### 错误2：CocoaPods 构建设置覆盖警告

**原因**：主项目的构建设置与 Pod 的设置冲突

**解决方案**：
1. 在主项目的构建设置中使用 `$(inherited)` 标志
2. 或者移除主项目中的 `EXCLUDED_ARCHS` 设置，让 Podfile 统一管理

### 错误3：架构不匹配错误

**原因**：framework 包含了不兼容的架构

**解决方案**：
1. 验证 framework 架构：`lipo -info path/to/framework`
2. 确保排除了模拟器上的 arm64 架构
3. 使用我们提供的模拟器检测代码

## 模拟器环境行为

在模拟器环境下，SDK 会返回以下响应：

- **初始化**: 成功，返回 "模拟器环境初始化成功"
- **检查环境**: 失败，返回错误码 "600024"
- **预取号**: 失败，返回 "模拟器环境不支持预取号"
- **一键登录**: 失败，返回 "模拟器环境不支持一键登录"
- **运营商类型**: 返回 "模拟器"

## 测试建议

1. **模拟器测试**: 用于UI调试和基本功能测试
2. **真机测试**: 用于完整的一键登录功能测试
3. **开发流程**: 在模拟器上开发UI，在真机上测试SDK功能

## 故障排除

### 如果仍然遇到链接错误：

1. 运行修复脚本：
   ```bash
   cd ios && ./fix_simulator.sh
   ```

2. 运行主项目修复脚本：
   ```bash
   cd your-project/ios && ./fix_main_project.sh
   ```

3. 检查 framework 完整性：
   ```bash
   lipo -info ios/libs/ATAuthSDK.framework/ATAuthSDK
   ```

4. 验证模拟器架构支持：
   ```bash
   file ios/libs/ATAuthSDK.framework/ATAuthSDK
   ```

### 常见问题

**Q: 为什么模拟器上不能正常使用一键登录？**

A: 阿里一键登录需要真实的运营商网络环境和SIM卡信息，模拟器无法提供这些条件。这是正常行为。

**Q: 如何在模拟器上测试登录逻辑？**

A: 可以在模拟器上测试UI和错误处理逻辑，真正的登录功能需要在真机上测试。

**Q: 修改后需要重新发布npm包吗？**

A: 需要。修改后请更新版本号并重新发布。

**Q: 为什么会有 CocoaPods 构建设置覆盖警告？**

A: 这是因为主项目和 Pod 都设置了相同的构建参数。使用 `$(inherited)` 标志可以解决这个问题。

## 技术实现

本修复方案通过以下技术实现：

1. **条件编译**: 使用 `TARGET_OS_SIMULATOR` 宏检测运行环境
2. **模拟类实现**: 在模拟器环境下提供SDK类的模拟实现
3. **架构配置**: 通过podspec配置避免架构冲突
4. **构建设置继承**: 使用 `$(inherited)` 避免设置覆盖冲突

## 联系支持

如果遇到其他问题，请：

1. 检查错误日志
2. 验证framework完整性
3. 运行诊断脚本
4. 提交issue并附上详细的错误信息 
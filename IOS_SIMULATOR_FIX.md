# iOS 模拟器兼容性修复指南

## 问题描述

在iOS模拟器上运行集成了阿里一键登录SDK的React Native项目时，可能遇到以下错误：

```
❌ ld: building for 'iOS-simulator', but linking in object file built for 'iOS'
```

## 解决方案

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

2. 检查 framework 完整性：
   ```bash
   lipo -info ios/libs/ATAuthSDK.framework/ATAuthSDK
   ```

3. 验证模拟器架构支持：
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

## 技术实现

本修复方案通过以下技术实现：

1. **条件编译**: 使用 `TARGET_OS_SIMULATOR` 宏检测运行环境
2. **模拟类实现**: 在模拟器环境下提供SDK类的模拟实现
3. **架构配置**: 通过podspec配置避免架构冲突

## 联系支持

如果遇到其他问题，请：

1. 检查错误日志
2. 验证framework完整性
3. 提交issue并附上详细的错误信息 
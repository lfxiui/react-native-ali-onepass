# iOS模拟器架构兼容性修复指南

## 问题描述

在Apple Silicon Mac和新版本Xcode中，使用阿里一键登录SDK时可能遇到以下错误：

```
❌ ld: building for 'iOS-simulator', but linking in object file (...ATAuthSDK.framework/ATAuthSDK[arm64]...) built for 'iOS'
```

这是因为第三方framework不包含`arm64-simulator`架构导致的。

## 解决方案

### 方案1: 自动修复脚本（推荐，保持arm64支持）

运行我们提供的自动修复脚本，它会保持Apple Silicon模拟器的arm64性能优势：

```bash
cd react-native-ali-onepass
./scripts/fix_simulator_support.sh
```

### 方案2: 现代XCFramework（最佳长期解决方案）

使用Xcode的现代XCFramework格式，原生支持所有架构：

```bash
cd react-native-ali-onepass
./scripts/build_xcframework.sh
```

### 方案3: Podfile配置（兼容性方案）

如果你的项目使用CocoaPods，优先在`ios/Podfile`中添加以下配置：

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # 确保支持所有架构
      config.build_settings['VALID_ARCHS'] = 'arm64 x86_64'
      
      # 如果上面的配置不工作，可以临时排除模拟器arm64
      # config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
    end
  end
end
```

然后重新安装pods：
```bash
cd ios
pod install
```

### 方案2: Xcode项目设置

1. 在Xcode中打开你的项目
2. 选择项目根节点（最顶层）
3. 选择你的app target
4. 进入 `Build Settings` 标签页
5. 搜索 `Excluded Architectures`
6. 在 `Excluded Architectures` 下找到 `Any iOS Simulator SDK`
7. 双击并添加 `arm64`

### 方案3: 手动修改项目文件

在你的项目的`project.pbxproj`文件中添加：

```
EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64;
```

### 方案4: 使用提供的脚本

在react-native-ali-onepass目录下运行：

```bash
./scripts/create_universal_framework.sh
```

## 验证修复

1. 清理项目缓存：
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   ```

2. 清理项目：
   ```bash
   # 在Xcode中：Product -> Clean Build Folder
   # 或者命令行：
   xcodebuild clean -workspace YourApp.xcworkspace -scheme YourApp
   ```

3. 重新编译项目

## 注意事项

- 这个配置只会影响模拟器编译，不会影响真机编译
- 在Apple Silicon Mac上，模拟器可能会运行在Rosetta模式下，但功能正常
- 如果你需要在Apple Silicon Mac的模拟器上运行arm64版本，需要联系SDK提供商更新framework以支持`arm64-simulator`架构

## 常见问题

**Q: 为什么要排除arm64架构？**
A: 第三方framework中的arm64是为真机编译的，与模拟器需要的arm64-simulator架构不兼容。

**Q: 这样设置会影响性能吗？**
A: 在Apple Silicon Mac上模拟器可能运行在Rosetta模式下，会有轻微性能影响，但不影响功能测试。

**Q: 真机编译会受影响吗？**
A: 不会，这个设置只影响模拟器编译。 
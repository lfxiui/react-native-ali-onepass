# 🚀 iOS模拟器快速修复指南

## ❌ 遇到的错误
```
ld: building for 'iOS-simulator', but linking in object file 
(...ATAuthSDK.framework/ATAuthSDK[arm64]...) built for 'iOS'
```

## ✅ 快速解决方案

### 步骤1: 运行修复脚本
在 `react-native-ali-onepass` 目录下运行：
```bash
./scripts/final_fix_simulator.sh
```

### 步骤2: 在你的主项目中配置Podfile
在你的主项目的 `ios/Podfile` 中添加以下配置：

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
      config.build_settings['VALID_ARCHS[sdk=iphonesimulator*]'] = 'x86_64'
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
    end
  end
end
```

### 步骤3: 清理和重新安装
```bash
# 清理Xcode缓存
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# 进入你的主项目ios目录
cd your_project/ios

# 重新安装pods
pod install

# 清理项目（在Xcode中）
# Product -> Clean Build Folder
```

### 步骤4: 重新编译
在Xcode中重新编译你的项目，现在应该可以在模拟器上正常运行了。

## 📋 验证修复
运行以下命令确认修复成功：
```bash
cd react-native-ali-onepass
lipo -info ios/libs/ATAuthSDK.framework/ATAuthSDK
```

应该显示：
```
Architectures in the fat file: ios/libs/ATAuthSDK.framework/ATAuthSDK are: x86_64 arm64
```

## 🔧 如果仍有问题

### 方案A: 在Xcode中手动设置
1. 打开你的项目
2. 选择项目target
3. 进入 Build Settings
4. 搜索 "Excluded Architectures"
5. 在 "Excluded Architectures" > "Any iOS Simulator SDK" 中添加 `arm64`

### 方案B: 恢复原始文件
如果需要恢复原始framework：
```bash
cd react-native-ali-onepass
for fw in ATAuthSDK YTXOperators YTXMonitor; do
  if [ -d "ios/libs/$fw.framework.backup" ]; then
    rm -rf "ios/libs/$fw.framework"
    mv "ios/libs/$fw.framework.backup" "ios/libs/$fw.framework"
  fi
done
```

## 📖 工作原理
这个解决方案的核心思路是：
- **真机**: 使用 `arm64` 架构，获得最佳性能
- **模拟器**: 使用 `x86_64` 架构，确保兼容性
- **自动选择**: 通过build settings配置自动选择合适的架构

## ⚡ 性能说明
- 真机性能：✅ 完全原生arm64性能
- 模拟器性能：⚠️ 在Apple Silicon Mac上会运行在Rosetta模式下，有轻微性能影响，但足够开发使用

## 💡 最佳实践
1. 开发阶段使用这个方案确保兼容性
2. 定期检查阿里SDK官方更新，可能会原生支持arm64-simulator
3. 如果不需要模拟器开发，可以直接使用原始SDK 
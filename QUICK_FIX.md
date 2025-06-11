# 🚨 紧急修复：iOS 模拟器库链接问题

如果你遇到以下错误：

```
❌ ld: library 'RNAliOnepass' not found
[!] Target overrides the EXCLUDED_ARCHS build setting
❌ property 'numberColor' not found on object of type 'TXCustomModel *'
❌ property 'loginBtnBgImgs' not found on object of type 'TXCustomModel *'
```

## 🚀 快速解决方案（5分钟内搞定）

### 步骤1：修复你的主项目 Podfile

在你的主项目 `ios/Podfile` 中，找到 `post_install` 部分并修改为：

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # 关键修复：使用继承而不是覆盖
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = '$(inherited) arm64'
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
    end
  end
  
  # 如果你使用新版本 React Native，保留这行
  react_native_post_install(installer) if respond_to?(:react_native_post_install)
end
```

### 步骤2：修复 Xcode 项目设置

1. 在 Xcode 中选择你的项目
2. 选择你的 Target
3. 进入 **Build Settings**
4. 搜索 **Excluded Architectures**
5. 在 **iOS Simulator** 下确保设置为：`$(inherited) arm64`
   - ⚠️ 重要：必须包含 `$(inherited)` 前缀！

### 步骤3：清理和重建

```bash
cd ios
rm -rf Pods/ Podfile.lock
pod install

# 在 Xcode 中清理构建文件夹 (Cmd+Shift+K)
# 删除 DerivedData (可选但推荐)
rm -rf ~/Library/Developer/Xcode/DerivedData
```

### 步骤4：更新到最新版本

确保使用最新版本以获得完整的属性支持：

```bash
npm install react-native-ali-onepass@^3.5.1
# 或者
yarn add react-native-ali-onepass@^3.5.1
```

### 步骤5：验证修复

重新运行你的项目，现在应该可以在模拟器上正常运行了！

## 🔍 问题原因

- **警告原因**：你的主项目设置覆盖了 Pod 的构建设置
- **库找不到**：架构冲突导致库没有为模拟器正确编译
- **解决原理**：使用 `$(inherited)` 让设置继承而不是覆盖

## 📞 如果还是不行

运行我们的自动修复脚本：

```bash
cd your-project/ios
curl -O https://raw.githubusercontent.com/yoonzm/react-native-ali-onepass/master/ios/fix_main_project.sh
chmod +x fix_main_project.sh
./fix_main_project.sh
```

或者查看详细文档：[iOS_SIMULATOR_FIX.md](./iOS_SIMULATOR_FIX.md) 
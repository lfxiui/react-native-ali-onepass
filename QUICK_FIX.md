# 🚨 紧急修复：iOS 模拟器库链接问题

如果你遇到以下错误：

```
❌ ld: library 'RNAliOnepass' not found
❌ ld: building for 'iOS-simulator', but linking in object file built for 'iOS'
[!] Target overrides the EXCLUDED_ARCHS build setting
❌ property 'numberColor' not found on object of type 'TXCustomModel *'
❌ property 'loginBtnBgImgs' not found on object of type 'TXCustomModel *'
```

## 🚀 最新解决方案（3.5.2版本）

### 核心原理
- **模拟器环境**：完全不链接阿里SDK的framework，使用纯代码模拟
- **真机环境**：正常链接所有阿里SDK framework
- **自动检测**：通过构建配置自动识别环境

### 步骤1：更新到最新版本

```bash
npm install react-native-ali-onepass@^3.5.2
# 或者
yarn add react-native-ali-onepass@^3.5.2
```

### 步骤2：修复主项目 Podfile

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

### 步骤3：修复 Xcode 项目设置

1. 在 Xcode 中选择你的项目
2. 选择你的 Target
3. 进入 **Build Settings**
4. 搜索 **Excluded Architectures**
5. 在 **iOS Simulator** 下确保设置为：`$(inherited) arm64`
   - ⚠️ 重要：必须包含 `$(inherited)` 前缀！

### 步骤4：彻底清理和重建

```bash
cd ios
rm -rf Pods/ Podfile.lock

# 重新安装（会应用新的framework配置）
pod install

# 清理所有缓存
rm -rf ~/Library/Developer/Xcode/DerivedData

# 在 Xcode 中清理构建文件夹 (Cmd+Shift+K)
```

### 步骤5：验证修复

重新运行你的项目，现在应该可以在模拟器上正常运行了！

## 🔍 技术原理

### 新版本的改进

1. **条件性Framework链接**：
   - 模拟器：`OTHER_LDFLAGS[sdk=iphonesimulator*]` 为空
   - 真机：`OTHER_LDFLAGS[sdk=iphoneos*]` 包含阿里SDK

2. **智能环境检测**：
   ```objc
   #if TARGET_OS_SIMULATOR || defined(RN_ALI_ONEPASS_SIMULATOR)
   // 使用模拟实现
   #else 
   // 使用真实SDK
   #endif
   ```

3. **避免架构冲突**：
   - 模拟器自动排除 arm64 架构
   - 真机正常链接所有架构

### 预期行为

- **模拟器环境**：
  - ✅ 正常编译和运行
  - ✅ SDK接口可调用
  - ⚠️ 返回模拟错误代码（正常行为）
  
- **真机环境**：
  - ✅ 完整的一键登录功能
  - ✅ 所有API正常工作

## 📞 如果还是不行

### 自动诊断脚本

```bash
cd your-project/ios
curl -O https://raw.githubusercontent.com/yoonzm/react-native-ali-onepass/master/ios/fix_main_project.sh
chmod +x fix_main_project.sh
./fix_main_project.sh
```

### 手动检查

1. **确认版本**：`npm list react-native-ali-onepass`
2. **检查配置**：查看 `Pods/Target Support Files/RNAliOnepass/RNAliOnepass.debug.xcconfig`
3. **验证framework**：确保模拟器构建时不包含阿里SDK链接

## 📚 更多帮助

- [详细修复指南](./iOS_SIMULATOR_FIX.md)
- [技术实现原理](./CHANGELOG.md) 
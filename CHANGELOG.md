# 变更日志

## [3.5.5] - 2024-12-19

### 🐛 关键Bug修复
- **修复真机环境条件编译问题**: 解决了真机环境下错误使用模拟器代码的问题
- **精确环境检测**: 使用 `RN_ALI_ONEPASS_DEVICE` 宏准确识别真机环境
- **SDK可用性检测**: 真机环境下通过 `__has_include(<ATAuthSDK/ATAuthSDK.h>)` 确保SDK可用

### 🔧 技术改进
- **三层条件编译逻辑**:
  1. 模拟器环境：`TARGET_OS_SIMULATOR || defined(RN_ALI_ONEPASS_SIMULATOR)`
  2. 真机环境：`defined(RN_ALI_ONEPASS_DEVICE) && __has_include(<ATAuthSDK/ATAuthSDK.h>)`
  3. 回退模式：SDK不可用时的安全实现
- **增强错误提示**: 区分不同环境的错误信息，便于调试

### 🛠️ 新增工具
- 添加真机调试脚本 `ios/debug_device_build.sh`
- 提供完整的环境检测和诊断功能

### 📋 修复步骤
1. 进入主项目: `cd [你的项目目录]`
2. 重新安装Pods: `cd ios && pod install --repo-update`
3. 清理缓存: `rm -rf ~/Library/Developer/Xcode/DerivedData`
4. 重新构建真机

## [3.5.1] - 2024-12-19

### 🔧 修复
- **编译错误修复**: 修复模拟器环境下 `TXCustomModel` 类属性缺失导致的编译错误
- **完善属性定义**: 为模拟器环境下的 `TXCustomModel` 添加了以下缺失属性：
  - `numberColor` - 手机号颜色
  - `numberFont` - 手机号字体
  - `loginBtnBgImgs` - 登录按钮背景图片数组
  - `autoHideLoginLoading` - 自动隐藏登录加载状态
  - `alertCornerRadiusArray` - 弹窗圆角半径数组
  - `contentViewFrameBlock` - 内容视图框架回调

### 🚀 改进
- 移除了可能导致主项目构建设置冲突的 podspec 配置
- 提供了完整的主项目配置修复指南
- 添加了自动诊断和修复脚本

### 📚 文档更新
- 新增 `QUICK_FIX.md` 5分钟快速修复指南
- 更新 `iOS_SIMULATOR_FIX.md` 添加新的错误处理方案
- 新增主项目配置示例和修复脚本

## [3.5.0] - 2024-12-19

### 🎉 新增特性
- **iOS 模拟器完全支持**: 新增模拟器环境检测和兼容性处理
- **条件编译**: 使用 `TARGET_OS_SIMULATOR` 宏在模拟器环境下提供模拟实现
- **架构优化**: 优化 podspec 配置，避免架构冲突

### 🔧 修复
- 修复 iOS 模拟器运行时的链接错误：`ld: building for 'iOS-simulator', but linking in object file built for 'iOS'`
- 修复模拟器环境下的SDK初始化问题
- 优化 framework 架构配置

### 🏗️ 技术改进
- 在模拟器环境下提供完整的SDK模拟实现
- 保持API接口一致性，便于开发调试
- 添加详细的错误处理和日志

### 📚 文档更新
- 新增 `iOS_SIMULATOR_FIX.md` 详细指南
- 更新 README.md 添加模拟器兼容性说明
- 添加故障排除脚本 `ios/fix_simulator.sh`

### ⚡ 模拟器环境行为
- 初始化：返回成功状态
- 环境检查：返回 "模拟器环境不支持" 错误码
- 预取号：返回相应的模拟错误信息
- 一键登录：返回模拟错误代码，不影响UI测试
- 运营商类型：返回 "模拟器"

### 🚀 使用建议
- **开发阶段**: 在模拟器上进行UI调试和基本功能测试
- **测试阶段**: 在真机上进行完整的一键登录功能测试
- **发布前**: 确保在真实设备上验证所有功能

### 📦 升级指南
从之前版本升级到 3.5.0：

1. 更新依赖：`npm install react-native-ali-onepass@^3.5.0`
2. 重新安装 Pods：`cd ios && rm -rf Pods/ && pod install`
3. 清理项目：在 Xcode 中执行 Clean Build Folder
4. 现在可以在模拟器上正常运行项目了！

---

## [3.4.0] - 之前版本

之前版本的变更记录...

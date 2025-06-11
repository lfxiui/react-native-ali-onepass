# react-native-ali-onepass

阿里一键登录SDK for React Native

## 🎯 特性

- ✅ 支持 iOS 和 Android
- ✅ **支持 iOS 模拟器运行**
- ✅ TypeScript 支持
- ✅ 完整的API接口
- ✅ 详细的错误处理

## 🚨 iOS 模拟器兼容性

**版本 3.5.0+ 已完全支持 iOS 模拟器！**

在模拟器环境下：
- ✅ 项目可以正常编译和运行
- ✅ SDK 接口保持一致，便于开发调试
- ⚠️ 返回模拟错误代码（因为模拟器无法访问运营商网络）
- 📱 真机环境下功能完全正常

详细信息请查看 [iOS模拟器兼容性修复指南](./iOS_SIMULATOR_FIX.md)

## Getting started

`$ npm install react-native-ali-onepass --save`

`$ yarn add react-native-ali-onepass`

### Mostly automatic installation

`$ react-native link react-native-ali-onepass`

### Manual installation


#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-ali-onepass` and add `RNAliOnepass.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libRNAliOnepass.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<

#### Android

1. Open up `android/app/src/main/java/[...]/MainActivity.java`
  - Add `import com.reactlibrary.RNAliOnepassPackage;` to the imports at the top of the file
  - Add `new RNAliOnepassPackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':react-native-ali-onepass'
  	project(':react-native-ali-onepass').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-ali-onepass/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      compile project(':react-native-ali-onepass')
  	```
4. Insert the following lines inside the android block in `android/app/build.gradle`:
  	```
      repositories {
          flatDir {
              dirs 'libs', '../../node_modules/react-native-ali-onepass/android/libs'
          }
      }
  	```

## [Example](https://github.com/yoonzm/react-native-ali-onepass/blob/master/example/App.js)


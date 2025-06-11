# react-native-ali-onepass

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
4. Run your project (`Cmd+R`)

##### iOS模拟器支持

如果在iOS模拟器上遇到架构相关的编译错误，我们提供了多种解决方案：

**方法1: 自动修复脚本（推荐）**
这个脚本会保持arm64架构支持，为Apple Silicon Mac提供最佳性能：

```bash
# 在react-native-ali-onepass目录下运行
./scripts/fix_simulator_support.sh
```

**方法2: 使用现代XCFramework**
创建支持所有架构的现代XCFramework格式：

```bash
# 在react-native-ali-onepass目录下运行
./scripts/build_xcframework.sh
```

**方法3: Podfile配置（兼容性方案）**
如果上述方法不工作，可以在你的项目的 `ios/Podfile` 中添加以下配置：

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # 确保支持所有需要的架构
      config.build_settings['VALID_ARCHS'] = 'arm64 x86_64'
      # 如果仍有问题，可以临时排除模拟器arm64
      # config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
    end
  end
end
```

**方法4: Xcode设置**
1. 在Xcode中打开你的项目
2. 选择你的项目target
3. 在 `Build Settings` 中搜索 `Valid Architectures`
4. 确保包含 `arm64` 和 `x86_64`

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


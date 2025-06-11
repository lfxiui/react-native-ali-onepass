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

如果在iOS模拟器上遇到架构相关的编译错误，请按以下步骤解决：

**方法1: 使用Podfile配置（推荐）**
在你的项目的 `ios/Podfile` 中添加以下配置：

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # 排除模拟器的arm64架构
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
    end
  end
end
```

**方法2: Xcode设置**
1. 在Xcode中打开你的项目
2. 选择你的项目target
3. 在 `Build Settings` 中搜索 `Excluded Architectures`
4. 在 `Excluded Architectures` > `Any iOS Simulator SDK` 中添加 `arm64`

**方法3: 使用提供的脚本**
```bash
# 在react-native-ali-onepass目录下运行
./scripts/create_universal_framework.sh
```

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


#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

// 检测是否在模拟器环境或强制模拟模式
#if TARGET_OS_SIMULATOR || defined(RN_ALI_ONEPASS_SIMULATOR)
// 模拟器环境下不导入阿里SDK
// 在这里声明必要的类型，避免编译错误
@class TXCommonHandler;
@class TXCustomModel;

#else
// 真机环境下导入阿里SDK
#if __has_include(<ATAuthSDK/ATAuthSDK.h>)
#import <ATAuthSDK/ATAuthSDK.h>
#import <ATAuthSDK/PNSReturnCode.h>
#else
// 如果头文件不存在，使用模拟模式
#define RN_ALI_ONEPASS_FALLBACK_SIMULATOR 1
@class TXCommonHandler;
@class TXCustomModel;
#endif
#endif

@interface RNAliOnepass : RCTEventEmitter <RCTBridgeModule>

@end
  

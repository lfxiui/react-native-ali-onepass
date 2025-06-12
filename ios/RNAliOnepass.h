#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

// 检测运行环境并配置相应的SDK导入
#if TARGET_OS_SIMULATOR || defined(RN_ALI_ONEPASS_SIMULATOR)
// 模拟器环境：使用模拟实现
@class TXCommonHandler;
@class TXCustomModel;

#elif defined(RN_ALI_ONEPASS_DEVICE) && __has_include(<ATAuthSDK/ATAuthSDK.h>)
// 真机环境且SDK可用：导入阿里SDK
#import <ATAuthSDK/ATAuthSDK.h>
#import <ATAuthSDK/PNSReturnCode.h>

#else
// 回退模式：SDK不可用时使用模拟实现
@class TXCommonHandler;
@class TXCustomModel;
#endif

@interface RNAliOnepass : RCTEventEmitter <RCTBridgeModule>

@end
  

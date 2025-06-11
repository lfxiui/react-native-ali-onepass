#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

// 检测是否在模拟器环境
#if TARGET_OS_SIMULATOR || defined(RN_ALI_ONEPASS_SIMULATOR)
// 模拟器环境下不导入阿里SDK
#else
// 真机环境下导入阿里SDK
#import <ATAuthSDK/ATAuthSDK.h>
#import <ATAuthSDK/PNSReturnCode.h>
#endif

@interface RNAliOnepass : RCTEventEmitter <RCTBridgeModule>

@end
  

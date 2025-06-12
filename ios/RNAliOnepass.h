#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

// 简化的环境检测
#if TARGET_OS_SIMULATOR
// 模拟器环境：使用模拟实现
@class TXCommonHandler;
@class TXCustomModel;

#else
// 真机环境：尝试导入阿里SDK
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
  

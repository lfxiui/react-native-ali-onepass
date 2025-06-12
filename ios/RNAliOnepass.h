#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

// 检测环境优先级：
// 1. 首先检查是否明确定义为模拟器模式
// 2. 然后检查是否在真实模拟器环境
// 3. 最后检查头文件是否可用

#if defined(RN_ALI_ONEPASS_SIMULATOR)
// 明确定义为模拟器模式
#define RN_ALI_ONEPASS_USE_SIMULATOR_MODE 1
@class TXCommonHandler;
@class TXCustomModel;

#elif TARGET_OS_SIMULATOR
// 真实模拟器环境
#define RN_ALI_ONEPASS_USE_SIMULATOR_MODE 1
@class TXCommonHandler;
@class TXCustomModel;

#else
// 真机环境 - 尝试导入阿里SDK
#if __has_include("ATAuthSDK.h") || __has_include(<ATAuthSDK/ATAuthSDK.h>) || defined(RN_ALI_ONEPASS_DEVICE)
// 阿里SDK可用，使用真机模式
#import "ATAuthSDK.h"
#import "PNSReturnCode.h"
#define RN_ALI_ONEPASS_USE_DEVICE_MODE 1

#else
// 头文件不可用，回退到模拟器模式但记录原因
#define RN_ALI_ONEPASS_USE_SIMULATOR_MODE 1
#define RN_ALI_ONEPASS_FALLBACK_SIMULATOR 1
@class TXCommonHandler;
@class TXCustomModel;
#endif
#endif

@interface RNAliOnepass : RCTEventEmitter <RCTBridgeModule>

@end
  

#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

// 更严格的环境检测逻辑
#if TARGET_OS_SIMULATOR
// 模拟器环境下不导入阿里SDK
// 在这里声明必要的类型，避免编译错误
@class TXCommonHandler;
@class TXCustomModel;
#define RN_ALI_ONEPASS_SIMULATOR_ENV 1

#elif defined(RN_ALI_ONEPASS_SIMULATOR)
// 手动强制模拟模式（用于测试）
@class TXCommonHandler;
@class TXCustomModel;
#define RN_ALI_ONEPASS_SIMULATOR_ENV 1

#else
// 真机环境下导入阿里SDK
#if __has_include(<ATAuthSDK/ATAuthSDK.h>)
#import <ATAuthSDK/ATAuthSDK.h>
#import <ATAuthSDK/PNSReturnCode.h>
#define RN_ALI_ONEPASS_DEVICE_ENV 1
#else
// 在真机上但头文件不存在的情况下，仍然尝试使用前向声明
// 这样可以避免编译错误，但运行时会让真正的SDK处理错误
@class TXCommonHandler;
@class TXCustomModel;
@class PNSReturnCode;
#define RN_ALI_ONEPASS_DEVICE_ENV 1
#warning "ATAuthSDK headers not found, but this is device build - will attempt runtime linking"
#endif
#endif

@interface RNAliOnepass : RCTEventEmitter <RCTBridgeModule>

@end
  

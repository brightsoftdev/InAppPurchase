

#ifdef TARGET_IPHONE_SIMULATOR
#define ILSimReplaceRealStoreKit 1
#import "ILSimStoreKit.h"
#else
#import <StoreKit/StoreKit.h>
#endif



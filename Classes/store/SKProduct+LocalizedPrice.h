

#import <Foundation/Foundation.h>

// SKProduct+LocalizedPrice.h

#import <Foundation/Foundation.h>
#import "store.h"

@interface SKProduct (LocalizedPrice)

@property(readonly, copy) NSString* localizedPrice;

@end 
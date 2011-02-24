

#import <UIKit/UIKit.h>
#import "StoreViewController.h"
#import "InAppPurchaseManager.h"

@interface InAppPurchaseAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
	StoreViewController* storeController;
	InAppPurchaseManager* purchaseManager;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) InAppPurchaseManager* purchaseManager;

@end


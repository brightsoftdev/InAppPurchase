//
//  InAppPurchaseAppDelegate.h
//  InAppPurchase
//
//  Created by Aaron Boxer on 11-02-22.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StoreViewController.h"

@interface InAppPurchaseAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
	StoreViewController* storeController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@end


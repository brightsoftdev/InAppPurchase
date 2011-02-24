#import <UIKit/UIKit.h>
#import "InAppPurchaseAppDelegate.h"

#define kBuyButtonTag   555 

typedef enum {
    ButtonStateHidden,
    ButtonStateDisabled,
    ButtonStateBuy,
    ButtonStateBuyDisabled,
    ButtonStateBought
    
} StoreTableCellButtonState;

@interface StoreTableCell : UITableViewCell <UIAlertViewDelegate> {
	UIButton* buyButton;
    StoreTableCellButtonState buttonState;
	NSString* productId;
}

-(void) addProgress;
-(void) purchaseCleanup:(NSString*)purchasedProductID;
-(void) setButtonState:(StoreTableCellButtonState)state;
-(void) updateButtonState;
-(void) update;
-(StoreTableCellButtonState) getButtonStateUnpurchased;
-(BOOL) alreadyPurchased;

@end

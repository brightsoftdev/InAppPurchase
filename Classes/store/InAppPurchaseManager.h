
#import <Foundation/Foundation.h>
#import "store.h"




// notifications sent out when the transaction completes
extern NSString* const kInAppPurchaseManagerTransactionCancelledNotification;
extern NSString* const kInAppPurchaseManagerTransactionFailedNotification;
extern NSString* const kInAppPurchaseManagerTransactionSucceededNotification ;
extern NSString* const kInAppPurchaseManagerProductsFetchedNotification;
extern NSString* const kInAppPurchaseManagerCanProvideContent;
extern NSString* const kInAppPurchaseManagerTransactionInProgressNotification;
extern NSString* const kInAppPurchaseManagerTransactionInitiatedNotification;

@interface InAppPurchaseManager : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver, UIAlertViewDelegate>
{
	@private
	NSMutableArray* alreadyPurchasedProductIds;
	NSArray* productIds;
    NSMutableDictionary* products;
    SKProductsRequest *productsRequest;
	
	NSTimer* progressTimer;
	NSMutableDictionary* progress;
	
	BOOL restoreCompleted;
	int restoreAttempts;

} 

+(void) setNeedsRestore:(BOOL)needs;
+(BOOL) needsRestore;
+(BOOL)canMakePurchases;

// public methods
-(id)   initWithIds:(NSArray*)pids;
-(BOOL) canPurchase:(NSString*)productID;
-(void) purchase:(NSString*)productId;
-(void) purchaseCleanup:(NSString*)productID;
-(void) restore;
-(BOOL) hasAlreadyPurchased:(NSSet*)productIDs;
-(void) clearAlreadyPurchased;
-(float) getProgress:(NSString*)productID;


@property (nonatomic, retain) NSMutableDictionary* products;
@property (nonatomic, retain) NSMutableDictionary* progress;


@end 
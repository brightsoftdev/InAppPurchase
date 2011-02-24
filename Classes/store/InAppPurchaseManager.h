
/* 
 *
 * Copyright (c) 2011, Aaron Boxer
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   * Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *   * Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *   * Neither the name of Redis nor the names of its contributors may be used
 *     to endorse or promote products derived from this software without
 *     specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */


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
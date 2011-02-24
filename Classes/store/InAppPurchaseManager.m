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


#import "InAppPurchaseManager.h"
#import "SKProduct+LocalizedPrice.h"
#import "NSString+NSStringAdditions.h"
#import "SFHFKeychainUtils.h"
#import "NSNotificationAdditions.h"



static BOOL needsRestore;

static NSString* const KEYCHAIN_PRODUCT_ID_USER = @"productId";
static NSString* const KEYCHAIN_SERVICE_NAME = @"MY_STORE_NAME";

@interface InAppPurchaseManager (private)

- (void)loadStore;
- (void)requestProductData:(NSArray*)productIds;
- (BOOL) validateReceipt:(SKPaymentTransaction*)transaction;
- (void)completeTransaction:(SKPaymentTransaction *)transaction;
- (void)restoreTransaction:(SKPaymentTransaction *)transaction;
- (void)failedTransaction:(SKPaymentTransaction *)transaction;
-(void)updateProgress:(NSTimer*)timer;
-(void) notifyProductsFetched;
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;
-(void) checkNeedsRestore;
@end


@implementation InAppPurchaseManager

NSString* const kInAppPurchaseManagerTransactionCancelledNotification = @"kInAppPurchaseManagerTransactionCancelledNotification";
NSString* const kInAppPurchaseManagerTransactionFailedNotification = @"kInAppPurchaseManagerTransactionFailedNotification";
NSString*  const kInAppPurchaseManagerTransactionSucceededNotification = @"kInAppPurchaseManagerTransactionSucceededNotification";
NSString*  const kInAppPurchaseManagerProductsFetchedNotification = @"kInAppPurchaseManagerProductsFetchedNotification";
NSString*  const kInAppPurchaseManagerCanProvideContent = @"kInAppPurchaseManagerCanProvideContent";
NSString*  const kInAppPurchaseManagerTransactionInProgressNotification = @"kInAppPurchaseManagerTransactionInProgressNotification";
NSString*  const kInAppPurchaseManagerTransactionInitiatedNotification = @"kInAppPurchaseManagerTransactionInitiatedNotification";

@synthesize products, progress;


#pragma -
#pragma Public methods


// InAppPurchaseManager.m

-(id) initWithIds:(NSArray*)pids{
	if (self = [super init]){
			
		productIds = [pids retain];	 
		

		progressTimer = nil;
		
		restoreCompleted = NO;
		restoreAttempts = 0;
		
		
		NSMutableDictionary* p = [NSMutableDictionary new];
		self.progress = p;
		[p release];
		
		[self loadStore];
		
		NSError* error;
		NSString* pass = [SFHFKeychainUtils getPasswordForUsername:KEYCHAIN_PRODUCT_ID_USER andServiceName:KEYCHAIN_SERVICE_NAME error:&error];
		if (pass != nil)	
			alreadyPurchasedProductIds = [[NSMutableArray alloc] initWithArray:[pass componentsSeparatedByString: @"|"]];
		else
			alreadyPurchasedProductIds = [NSMutableArray new];
		
		[self checkNeedsRestore];
			
		
	}
	return self;
}

-(void) checkNeedsRestore{
	if (needsRestore) {
		
		NSString* title = @"RESTORE PURCHASED CONTENT";
		NSString* msg = @"Would you like to check the App Store for previously purchased video content?";
		UIAlertView * alert = [[[UIAlertView alloc] initWithTitle:title message:msg delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK",nil] autorelease];
		[alert show];	
	}			
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
	if (buttonIndex == 1){
		[self restore];
	} else {
		needsRestore = NO;
		restoreCompleted = YES;
	}

}

-(void) dealloc{
	
	[productIds release];
	[products release];
	[alreadyPurchasedProductIds release];
	
	[super dealloc];
}

//
// call this method once on startup
//
- (void) loadStore {
	
	if ([InAppPurchaseManager canMakePurchases]){
		// restarts any purchases if they were interrupted last time the app was open
		[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
		
		// get the product description (defined in early sections)
		[self requestProductData:productIds];
		
	}
}

//
// call this before making a purchase
//
+ (BOOL)canMakePurchases
{
    return [SKPaymentQueue canMakePayments];
}

#pragma mark -
#pragma mark Restore methods

-(void) restore{
	
	restoreAttempts++;
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];

}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue{
	[self paymentQueue:queue updatedTransactions:queue.transactions];	
	restoreCompleted = YES;
	if (products != nil) {
		needsRestore = NO;
		[self notifyProductsFetched];
	}
	
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error{
	NSString* title = @"Restore Purchases Failed";
	NSString* msg;
	if (restoreAttempts == 1)
	  msg = @"An attempt to restore previously purchased content has failed. Trying again";
	else
		 msg = @"Two attempts to restore previously purchased content have failed. Please re-install app";
	UIAlertView * alert = [[[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease];
	[alert show];
	if (restoreAttempts == 1){
		[self restore];
	} else {
		restoreCompleted = YES;
		if (products != nil) {
			[self notifyProductsFetched];
			needsRestore = NO;
		}	
	}

}

#pragma mark -

-(void)updateProgress:(NSTimer*)timer {
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:kInAppPurchaseManagerTransactionInProgressNotification object:self userInfo:nil];
	for (NSString* ID in [progress allKeys]){
		
		NSNumber* prog = [progress valueForKey:ID];
		NSNumber* newProg = [NSNumber numberWithFloat:([prog floatValue] + 0.01)];
		[progress setValue:newProg forKey:ID];
		
	}
}

-(float) getProgress:(NSString*)productID{
	
	NSNumber* prog = [progress valueForKey:productID];
    if (prog == nil)
		return -1;
	else 
		return [prog floatValue];
}

//
// kick off the transaction
//
- (void)purchase:(NSString*)productId
{
	BOOL newTimer = [progress count] == 0;
	[progress setValue:[NSNumber numberWithFloat:0] forKey:productId];
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:kInAppPurchaseManagerTransactionInitiatedNotification object:self userInfo:nil];

	if (newTimer) {
		[progressTimer invalidate];	
		progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(updateProgress:) userInfo:nil repeats:YES]; 
	}

	
    SKPayment *payment = [SKPayment paymentWithProductIdentifier:productId];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

#pragma mark -
#pragma mark Purchase helpers


- (BOOL) validateReceipt:(SKPaymentTransaction*)transaction
{
	NSData* receipt = transaction.transactionReceipt;
	NSString* codedReceipt = [NSString base64StringFromData:receipt length:[receipt length]];
	
	//hit web service to validate receipt
	
	return YES;
	
	
}

-(BOOL) hasAlreadyPurchased:(NSSet*) productIDs{
	BOOL donePurchased = NO;
	for (NSString* pid in productIDs){
		if ([alreadyPurchasedProductIds containsObject:pid] ) {
		    donePurchased = YES;
			break;

		}
	}
	return donePurchased;
	
}

-(BOOL) canPurchase:(NSString*)productID{
	
	SKProduct* product = [ products valueForKey:productID];
	return !(product == nil || needsRestore );

}

//
// saves a record of the transaction by storing the receipt to disk
//
- (void)recordTransaction:(SKPaymentTransaction *)transaction
{
	
	NSError* error;
	NSString* pass = [SFHFKeychainUtils getPasswordForUsername:KEYCHAIN_PRODUCT_ID_USER andServiceName:KEYCHAIN_SERVICE_NAME error:&error];

	NSString* newPass;
	NSString* productID = transaction.payment.productIdentifier; 
	if (pass == nil || [pass length] == 0)
		newPass = productID;
	else
	  newPass = [pass stringByAppendingFormat:@"|%@",productID];
	
	[alreadyPurchasedProductIds addObject:productID];
	
	[SFHFKeychainUtils storeUsername:KEYCHAIN_PRODUCT_ID_USER andPassword:newPass forServiceName:KEYCHAIN_SERVICE_NAME updateExisting:YES error:&error];

 
}

-(void) clearAlreadyPurchased{
	NSError* error;
	[SFHFKeychainUtils storeUsername:KEYCHAIN_PRODUCT_ID_USER andPassword:@"" forServiceName:KEYCHAIN_SERVICE_NAME updateExisting:YES error:&error];
	[alreadyPurchasedProductIds removeAllObjects];
	needsRestore = YES;
	restoreCompleted = NO;
	[self checkNeedsRestore];
}


- (void)provideContent:(NSString *)productId
{
	// send out a notification that content can be provided
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:productId forKey:@"productId"];
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:kInAppPurchaseManagerCanProvideContent object:self userInfo:userInfo];

	
}

//
// removes the transaction from the queue and posts a notification with the transaction result
//
- (void)finishTransaction:(SKPaymentTransaction *)transaction wasSuccessful:(BOOL)wasSuccessful
{
    // remove the transaction from the payment queue.
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
	
	//do notifications and cleanup on original transaction if this is a restore
	if (transaction.transactionState == SKPaymentTransactionStateRestored)
		transaction = transaction.originalTransaction;
	
	[self purchaseCleanup:transaction.payment.productIdentifier];
	
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:transaction, @"transaction" , nil];
    if (wasSuccessful)
    {
        // send out a notification that we’ve finished the transaction
        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:kInAppPurchaseManagerTransactionSucceededNotification object:self userInfo:userInfo];
    }
    else
    {
        // send out a notification for the failed transaction
        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:kInAppPurchaseManagerTransactionFailedNotification object:self userInfo:userInfo];
    }
}



-(void) purchaseCleanup:(NSString*)productID{
	[progress removeObjectForKey:productID];
	if ([progress count] == 0){
		[progressTimer invalidate];
		progressTimer = nil;
	}

}


#pragma mark -
#pragma mark SKPaymentTransactionObserver methods

//
// called when the transaction status is updated
//
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
                break;
            default:
                break;
        }
	}
}


//
// called when the transaction was successfull
//
- (void)completeTransaction:(SKPaymentTransaction *)transaction
{
    [self recordTransaction:transaction];
    [self provideContent:transaction.payment.productIdentifier];
    [self finishTransaction:transaction wasSuccessful:YES];
}

//
// called when a transaction has been restored and and successfully completed
//
- (void)restoreTransaction:(SKPaymentTransaction *)transaction
{
    [self recordTransaction:transaction.originalTransaction];
    [self provideContent:transaction.originalTransaction.payment.productIdentifier];
    [self finishTransaction:transaction wasSuccessful:YES];

}

//
// called when a transaction has failed
//
- (void)failedTransaction:(SKPaymentTransaction *)transaction
{
	[self purchaseCleanup:transaction.payment.productIdentifier];
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        // error!
        [self finishTransaction:transaction wasSuccessful:NO];
    }
    else
    {
		[self purchaseCleanup:transaction.payment.productIdentifier];
		
		// this is fine, the user just cancelled, so don’t notify
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
		
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:transaction, @"transaction" , nil];
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:kInAppPurchaseManagerTransactionCancelledNotification object:self userInfo:userInfo];
		
    }
	
}


- (void)requestProductData:(NSArray*)myProductIds
{
	//remove product ids that have already been purchased
	NSMutableSet* productIdentifiers = [[NSMutableSet alloc] initWithArray:myProductIds];
	for (NSString* pid in alreadyPurchasedProductIds){
		[productIdentifiers removeObject:pid];
		
	}
    productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
    productsRequest.delegate = self;
    [productsRequest start];
    
    // we will release the request object in the delegate callback
}

#pragma mark -
#pragma mark SKProductsRequestDelegate methods

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
	//store list of products
	NSMutableDictionary* newProducts = [NSMutableDictionary new];
	for (SKProduct* product in response.products){
		[newProducts setObject:product forKey:product.productIdentifier];
	}
	self.products = newProducts;
	[newProducts release];
 
	//log invalid product ids
    for (NSString *invalidProductId in response.invalidProductIdentifiers)
    {
        NSLog(@"Invalid product id: %@" , invalidProductId);
    }
    
    // finally release the reqest we alloc/init’ed in requestProductData
    [productsRequest release];

	//if restore has been requested, but hasn't received a response, then don't notify
	
    if (!needsRestore)
		[self notifyProductsFetched];
	else if (restoreCompleted){  //restore has already received response
		needsRestore = NO;
		[self notifyProductsFetched];
	}
} 

-(void) notifyProductsFetched{
	
	//notify observers
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:kInAppPurchaseManagerProductsFetchedNotification object:self userInfo:nil];

}

+(void) setNeedsRestore:(BOOL)needs{
	needsRestore = needs;;	
}

+(BOOL) needsRestore{
	
	return needsRestore;	
}

@end

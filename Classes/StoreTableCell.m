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


#import "StoreTableCell.h"
#import "SKProduct+LocalizedPrice.h"


@interface StoreTableCell (private)
-(void) startProgress;
-(void) stopProgress;
-(void) setButtonStateBuy;
-(void)purchase;
-(void) purchaseInProgress:(NSNotification*) notif;
-(NSString*) getPrice;
-(InAppPurchaseAppDelegate*) getDelegate;
-(BOOL) isPurchaseInProgress:(BOOL)alsoChildren;
@end



@implementation StoreTableCell


-(InAppPurchaseAppDelegate*) getDelegate{
	return (InAppPurchaseAppDelegate*)[[UIApplication sharedApplication] delegate];
}

- (void) cleanup
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopProgress];
}



- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}




- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {	
        buttonState = ButtonStateDisabled;
		productId = @"TestItem";
		if (productId != nil) {
		
			// Initialization code        
			CGFloat xOffset = 230;
			CGFloat yOffset = 20;
			
			buyButton = [UIButton buttonWithType:UIButtonTypeCustom];
			buyButton.tag = kBuyButtonTag;
			buyButton.frame = CGRectMake(xOffset, yOffset, 75, 25);
			
			
            buyButton.titleLabel.font = [UIFont boldSystemFontOfSize:15];
			
			
            [buyButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [buyButton setTitleColor:[UIColor grayColor] forState:UIControlStateSelected];
			
			
			[buyButton addTarget:self action:@selector(performAction:) forControlEvents:UIControlEventTouchUpInside];
			
			
			[self addSubview:buyButton];
            
            UIProgressView *progress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
			
            progress.tag = 1111;
            progress.hidden = YES;
            
			[self addSubview:progress];
            
			[progress release];
		}
        self.clipsToBounds = YES;
    }
    [self setNeedsLayout];
    return self;
}




- (void) performAction:(id)sender
{
	if ([self alreadyPurchased] ) {
	// do something!!!!
		
		
	} else
		[self purchase];
	
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
	if (buttonIndex == 1){
	    [self purchase];
	}
}



#pragma mark -
#pragma mark Purchase




-(BOOL) isPurchaseInProgress:(BOOL)alsoChildren{
	BOOL inProgress = NO;

    float prog = [[self getDelegate].purchaseManager getProgress:productId];
	inProgress = (prog != -1);
	
	return inProgress;

	
}

-(BOOL) alreadyPurchased{
	NSMutableSet* productIDs = [[NSMutableSet new] autorelease];
	if (productId != nil)
		[productIDs addObject:productId];	
	
	return [[self getDelegate].purchaseManager hasAlreadyPurchased:productIDs ];	
}

-(void) purchase{
    [ [self getDelegate].purchaseManager purchase:productId ];	
}



#pragma mark -
#pragma mark Progress

- (void) startProgress
{
	float progressValue = [ [self getDelegate].purchaseManager getProgress:productId ];
	if (progressValue == -1)
		return;
	
    UIProgressView *progress = (UIProgressView*)[self viewWithTag:1111];
    CGFloat newX = 12;
    CGFloat newY = self.frame.size.height - 20;
    progress.frame = CGRectMake(newX, newY, 296, 9);
    progress.hidden = NO;
}


- (void) addProgress
{
	float progressValue = [ [self getDelegate].purchaseManager getProgress:productId ];
	if (progressValue == -1)
		return;
	
	UIProgressView *progress = (UIProgressView*)[self viewWithTag:1111];
	if (progress.hidden)
		[self startProgress];
    progress.progress = progressValue;
}

- (void) stopProgress
{

    UIProgressView *progress = (UIProgressView*)[self viewWithTag:1111];
    if (progress != nil)
        progress.hidden = YES;
    
    [self updateButtonState];
}

-(void) purchaseCleanup:(NSString*)purchasedProductID{
	if ([productId isEqualToString:purchasedProductID])
		[self stopProgress];
	[self update];

	
}

-(void) update{
	float progressValue = [ [self getDelegate].purchaseManager getProgress:productId ];
	if (progressValue == -1)
		[self stopProgress];
	[self updateButtonState];
}


#pragma mark -
#pragma mark Button State

-(NSString*) getPrice{
	SKProduct* product = [[self getDelegate].purchaseManager.products valueForKey:productId ];
	NSString* price = nil;
	if (product != nil)
       price = [product localizedPrice];
	else
		price = @"BUY";
	return price;
}

-(void) setButtonStateBuy{
	[buyButton setBackgroundImage:[UIImage imageNamed:@"btn_lrg-enabled.png"] forState:UIControlStateNormal];
	[buyButton setBackgroundImage:[UIImage imageNamed:@"btn_lrg-disabled.png"] forState:UIControlStateDisabled];
    [buyButton setBackgroundImage:[UIImage imageNamed:@"btn_lrg-pressed.png"] forState:UIControlStateHighlighted];
	
	
	NSString* price = [self getPrice];
	[buyButton setTitle:price forState:UIControlStateNormal];
	[buyButton setTitle:price forState:UIControlStateDisabled];	
}

-(void) setButtonState:(StoreTableCellButtonState) state
{
    buttonState = state;
    
	if (buyButton == nil || ([buyButton superview] == nil) )
		return;
	
    buyButton.hidden = NO;
    switch (state) {
        case ButtonStateHidden:
            buyButton.hidden = YES;
            break;
        case ButtonStateDisabled:
			
			//set background
            [buyButton setBackgroundImage:[UIImage imageNamed:@"btn_lrg-disabled.png"] forState:UIControlStateDisabled];
            [buyButton setBackgroundImage:[UIImage imageNamed:@"btn_lrg-disabled.png"] forState:UIControlStateSelected];
            [buyButton setBackgroundImage:[UIImage imageNamed:@"btn_lrg-enabled.png"] forState:UIControlStateHighlighted];
            [buyButton setBackgroundImage:[UIImage imageNamed:@"btn_lrg-enabled.png"] forState:UIControlStateNormal];
			
            buyButton.enabled = NO;
            break;
        case ButtonStateBuy:
			
			// don't enable if purchase in progress
			buyButton.enabled = ![self isPurchaseInProgress:YES];
			[self setButtonStateBuy];
			
            break;
        case ButtonStateBuyDisabled:
            buyButton.enabled = NO;
			
			// set background
			[buyButton setBackgroundImage:[UIImage imageNamed:@"btn_lrg-disabled.png"] forState:UIControlStateNormal];
            [buyButton setBackgroundImage:[UIImage imageNamed:@"btn_lrg-disabled.png"] forState:UIControlStateDisabled];
            [buyButton setBackgroundImage:[UIImage imageNamed:@"btn_lrg-disabled.png"] forState:UIControlStateHighlighted];

            NSString* price = [self getPrice];
			
			// set price text
            [buyButton setTitle:price forState:UIControlStateNormal];
            [buyButton setTitle:price forState:UIControlStateDisabled];	
			break;
        case ButtonStateBought:
            buyButton.enabled = NO;
			
			// clear background image
            [buyButton setBackgroundImage:nil forState:UIControlStateNormal];
            [buyButton setBackgroundImage:nil forState:UIControlStateDisabled];
            [buyButton setBackgroundImage:nil forState:UIControlStateSelected];
			
			// set image
            [buyButton setImage:[UIImage imageNamed:@"Bought_Check_btn.png"] forState:UIControlStateDisabled];
            [buyButton setImage:[UIImage imageNamed:@"Bought_Check_btn.png"] forState:UIControlStateHighlighted];
            [buyButton setImage:[UIImage imageNamed:@"Bought_Check_btn.png"] forState:UIControlStateNormal];
            
			// clear text
			[buyButton setTitle:@"" forState:UIControlStateNormal];
            [buyButton setTitle:@"" forState:UIControlStateDisabled];
            [buyButton setTitle:@"" forState:UIControlStateHighlighted];
            [buyButton setTitle:@"" forState:UIControlStateSelected];
           break;
        default:
            break;
    }
    [self setNeedsLayout];
}


-(StoreTableCellButtonState) getButtonStateUnpurchased{
	StoreTableCellButtonState state = ButtonStateBuyDisabled;
	if (productId != nil) {
		if ([[self getDelegate].purchaseManager canPurchase:productId])
			state =  ButtonStateBuy;	
	}

	return state;
	
}

-(void) updateButtonState{
	StoreTableCellButtonState state = buttonState;
	if (![self alreadyPurchased]){
		state = [self getButtonStateUnpurchased];
		
	} else {

	   state = ButtonStateBought;
        
	}
	[self setButtonState:state];
}


@end

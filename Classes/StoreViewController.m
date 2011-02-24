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


#import "StoreViewController.h"
#import "StoreTableCell.h"

@interface StoreViewController (private)
- (void)purchaseInitiated:(NSNotification *)notif;
- (void)purchaseInProgress:(NSNotification *)notif;
- (void)productPurchased:(NSNotification *)notif;
- (void)purchaseFailed:(NSNotification *)notif;
- (void)purchaseCancelled:(NSNotification *)notif;
- (void)productsFetched:(NSNotification *)notif;
-(void) purchaseCleanup:(NSNotification*)notif;
@end



@implementation StoreViewController


#pragma mark -
#pragma mark Initialization

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if ((self = [super initWithStyle:style])) {
    }
    return self;
}
*/


#pragma mark -
#pragma mark View lifecycle

/*
- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
*/

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	
	[center addObserver:self selector:@selector(purchaseInitiated:)
				   name:kInAppPurchaseManagerTransactionInitiatedNotification object:nil];
	
	[center addObserver:self selector:@selector(purchaseInProgress:)
				   name:kInAppPurchaseManagerTransactionInProgressNotification object:nil];
	
	[center addObserver:self selector:@selector(productPurchased:)
				   name:kInAppPurchaseManagerTransactionSucceededNotification object:nil];
	
	[center addObserver:self selector:@selector(purchaseCancelled:)
				   name:kInAppPurchaseManagerTransactionFailedNotification object:nil];
	
	[center addObserver:self selector:@selector(purchaseCancelled:)
				   name:kInAppPurchaseManagerTransactionCancelledNotification object:nil];
	
	[center addObserver:self selector:@selector(productsFetched:) 
				   name:kInAppPurchaseManagerProductsFetchedNotification object:nil];
	
	NSArray* visible = self.tableView.visibleCells;
	for (StoreTableCell* cell in visible)
			[cell update];
	
}

/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/

- (void)viewDidDisappear:(BOOL)animated {
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center removeObserver:self name:kInAppPurchaseManagerTransactionInitiatedNotification object:nil];
	[center removeObserver:self name:kInAppPurchaseManagerTransactionInProgressNotification object:nil];	
	[center removeObserver:self name:kInAppPurchaseManagerTransactionSucceededNotification object:nil];
	[center removeObserver:self name:kInAppPurchaseManagerTransactionFailedNotification object:nil];
	[center removeObserver:self name:kInAppPurchaseManagerTransactionCancelledNotification object:nil];
	[center removeObserver:self name:kInAppPurchaseManagerProductsFetchedNotification object:nil];	
    [super viewDidDisappear:animated];
}

- (void)purchaseInProgress:(NSNotification *)notif{
    for (StoreTableCell* cell in self.tableView.visibleCells){
		[cell addProgress];
	}
}
- (void)productPurchased:(NSNotification *)notif{
	[self purchaseCleanup:notif];
	[self.tableView reloadData];
	
}
- (void)purchaseFailed:(NSNotification *)notif{
	[self purchaseCleanup:notif];	
	NSString* title = @"Purchase Failure";
	NSString* msg = @"Purchase Failure";
	UIAlertView * alert = [[[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease];
	[alert show];
}

- (void)purchaseCancelled:(NSNotification *)notif{
	[self purchaseCleanup:notif];	
	
}

- (void)productsFetched:(NSNotification *)notif{
	for (StoreTableCell* cell in self.tableView.visibleCells){
		[cell update];
	}
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kInAppPurchaseManagerProductsFetchedNotification object:nil];
	
}

- (void)purchaseInitiated:(NSNotification *)notif{
	for (StoreTableCell* cell in self.tableView.visibleCells){
		[cell update];
	}
}

-(void) purchaseCleanup:(NSNotification*)notif;{
	SKPaymentTransaction* transaction = [notif.userInfo valueForKey:@"transaction"];
	NSString* productID = transaction.payment.productIdentifier;
	//stop progress on cells
	for (StoreTableCell* cell in self.tableView.visibleCells)
		[cell purchaseCleanup:productID];
	
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


- (CGFloat) tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGFloat height = 100;
	return height;	
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[StoreTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	/*
	 <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
	 [self.navigationController pushViewController:detailViewController animated:YES];
	 [detailViewController release];
	 */
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end


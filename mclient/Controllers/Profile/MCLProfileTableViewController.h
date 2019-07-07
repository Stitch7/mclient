//
//  MCLProfileTableViewController.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLLoadingViewControllerDelegate.h"

@protocol MCLDependencyBag;
@class MCLUser;

@interface MCLProfileTableViewController : UITableViewController <MCLLoadingViewControllerDelegate>

@property (strong, nonatomic) id <MCLDependencyBag> bag;
@property (strong, nonatomic) MCLUser *user;
@property (weak, nonatomic) MCLLoadingViewController *loadingViewController;
@property (assign, nonatomic) BOOL showPrivateMessagesButton;

@end

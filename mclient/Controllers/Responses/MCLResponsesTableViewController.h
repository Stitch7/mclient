//
//  MCLResponsesTableViewController.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLMessageResponsesRequest.h"
#import "MCLLoadingViewControllerDelegate.h"

@protocol MCLDependencyBag;
@class MCLLoadingViewController;
@class MCLResponseContainer;

@interface MCLResponsesTableViewController : UITableViewController <MCLLoadingViewControllerDelegate>

@property (weak, nonatomic) MCLLoadingViewController *loadingViewController;
@property (strong, nonatomic) MCLResponseContainer *responseContainer;

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag;

@end

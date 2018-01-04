//
//  MCLResponsesTableViewController.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLMessageResponsesRequest.h"
#import "MCLLoadingViewControllerDelegate.h"

@protocol MCLDependencyBag;
@class MCLResponseContainer;

@interface MCLResponsesTableViewController : UITableViewController <MCLLoadingViewControllerDelegate>

@property (strong, nonatomic) MCLResponseContainer *responseContainer;

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag;

@end

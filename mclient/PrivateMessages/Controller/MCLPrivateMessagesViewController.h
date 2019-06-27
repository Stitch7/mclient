//
//  MCLPrivateMessagesViewController.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLLoadingViewControllerDelegate.h"

@protocol MCLDependencyBag;

@interface MCLPrivateMessagesViewController : UITableViewController <MCLLoadingViewControllerDelegate>

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag;

@end

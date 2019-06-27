//
//  MCLDetailViewController.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLLoadingViewControllerDelegate.h"

@protocol MCLDependencyBag;

@interface MCLDetailViewController : UIViewController <MCLLoadingViewControllerDelegate>

@property (strong, nonatomic) id <MCLDependencyBag> bag;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *tableViewLeadingConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *tableViewTrailingConstraint;

@property (strong, nonatomic) NSMutableArray *favorites;

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag;

@end

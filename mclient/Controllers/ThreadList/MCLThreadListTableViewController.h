//
//  MCLThreadListTableViewController.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MGSwipeTableCell.h"

#import "MCLLoadingViewControllerDelegate.h"
#import "MCLComposeMessageViewController.h"
#import "MCLMessageListViewController.h"

extern NSString * const MCLFavoritedChangedNotification;

@protocol MCLDependencyBag;

@class MCLBoard;

@interface MCLThreadListTableViewController : UITableViewController <MGSwipeTableCellDelegate, MCLLoadingViewControllerDelegate, MCLComposeMessageViewControllerDelegate, MCLMessageListDelegate, UISearchControllerDelegate, UISearchResultsUpdating>

@property (strong, nonatomic) id <MCLDependencyBag> bag;
@property (strong, nonatomic) MCLBoard *board;
@property (strong, nonatomic) NSMutableArray *threads;

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag;

@end

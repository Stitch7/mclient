//
//  MCLBoardListTableViewController.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MGSwipeTableCell.h"

#import "MCLLoadingViewControllerDelegate.h"
#import "MCLSettingsViewController.h"

@protocol MCLDependencyBag;

@interface MCLBoardListTableViewController : UITableViewController <MGSwipeTableCellDelegate, MCLLoadingViewControllerDelegate, MCLSettingsTableViewControllerDelegate>

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag;

@end

//
//  MCLBoardListTableViewController.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MGSwipeTableCell.h"

#import "MCLLoadingViewControllerDelegate.h"
#import "MCLSettingsViewController.h"
#import "MCLMessageListViewController.h"
#import "MCLNoDataViewPresentingViewController.h"

// Sections
typedef NS_ENUM(NSInteger, MCLBoardListSection) {
    MCLBoardListSectionBoards = 0,
    MCLBoardListSectionFavorites = 1,
};

@protocol MCLDependencyBag;

@interface MCLBoardListTableViewController : UITableViewController <MGSwipeTableCellDelegate, MCLLoadingViewControllerDelegate, MCLMessageListDelegate, MCLNoDataViewPresentingViewController>

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag;

- (void)updateVerifyLoginViewWithSuccess:(BOOL)success;

@end

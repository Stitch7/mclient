//
//  MCLRouter+mainNavigation.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLRouter.h"

@class MCLBoard;
@class MCLThread;
@class MCLMessage;
@class MCLUser;
@class MCLSettingsViewController;
@class MCLSearchTableViewController;
@class MCLResponsesTableViewController;
@class MCLProfileTableViewController;
@class MCLThreadListTableViewController;
@class MCLMessageListViewController;

@interface MCLRouter (mainNavigation)

- (MCLSettingsViewController *)modalToSettings;
- (MCLProfileTableViewController *)modalToProfileFromUser:(MCLUser *)user;
- (MCLSearchTableViewController *)pushToSearchWithBoards:(NSArray<MCLBoard *>*)boards;
- (MCLResponsesTableViewController *)pushToResponses;
- (MCLThreadListTableViewController *)pushToThreadListFromBoard:(MCLBoard *)board;
- (MCLMessageListViewController *)pushToThread:(MCLThread *)thread;
- (MCLMessageListViewController *)pushToThread:(MCLThread *)thread onMasterNavigationController:(UINavigationController *)masterNavigationController;
- (MCLMessageListViewController *)pushToMessage:(MCLMessage *)message;
- (MCLMessageListViewController *)pushToMessage:(MCLMessage *)message onMasterNavigationController:(UINavigationController *)masterNavigationController;

@end

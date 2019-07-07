//
//  MCLMessageListViewController.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLLoadingViewControllerDelegate.h"
#import "MCLComposeMessageViewControllerDelegate.h"
#import "MCLMessageToolbarDelegate.h"
#import "MCLMessageKeyboardShortcutsDelegate.h"
#import "MCLRouter+composeMessage.h"
#import "MCLTheme.h"

@protocol MCLDependencyBag;
@protocol MCLMessageListDelegate;

@class MCLLogin;
@class MCLBoard;
@class MCLThread;
@class MCLMessageToolbarController;

@interface MCLMessageListViewController : UIViewController <MCLLoadingViewControllerDelegate, MCLComposeMessageViewControllerDelegate, MCLMessageKeyboardShortcutsDelegate>

@property (strong, nonatomic) id <MCLDependencyBag> bag;
@property (weak, nonatomic) id <MCLMessageListDelegate> delegate;
@property (weak, nonatomic) MCLLoadingViewController *loadingViewController;
@property (strong, nonatomic) NSMutableArray *messages;
@property (strong, nonatomic) MCLBoard *board;
@property (strong, nonatomic) MCLThread *thread;
@property (strong) NSNumber *jumpToMessageId;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UIView *refreshControlBackgroundView;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) MCLMessageToolbarController *messageToolbarController;
@property (assign, nonatomic) BOOL selectAfterScroll;

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag;

- (void)initialize;
- (void)themeChanged:(NSNotification *)notification;
- (void)selectInitialMessage;

@end

@protocol MCLMessageListDelegate <NSObject>

- (void)messageListViewController:(MCLMessageListViewController *)inController didFinishLoadingThread:(MCLThread *)inThread;
- (void)messageListViewController:(MCLMessageListViewController *)inController didReadMessageOnThread:(MCLThread *)inThread;

@end

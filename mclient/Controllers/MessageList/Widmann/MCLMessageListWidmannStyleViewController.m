//
//  MCLMessageListWidmannStyleViewController.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLMessageListWidmannStyleViewController.h"

#import "UIViewController+Additions.h"
#import "MCLDependencyBag.h"
#import "MCLSettings.h"
#import "MCLThemeManager.h"
#import "MCLNotificationManager.h"
#import "UIView+addConstraints.h"
#import "MCLMessageRequest.h"
#import "MCLProfileTableViewController.h"
#import "MCLMessageListWidmannStyleTableViewCell.h"
#import "MCLUser.h"
#import "MCLBoard.h"
#import "MCLThread.h"
#import "MCLMessage.h"
#import "MCLNotificationHistory.h"
#import "MCLDetailNavigationController.h"
#import "MCLMessageToolbarController.h"
#import "MCLMessageToolbar.h"


@interface MCLMessageListWidmannStyleViewController ()

@property (assign, nonatomic) CGFloat selectedCellHeight;

@end

@implementation MCLMessageListWidmannStyleViewController

#pragma mark - ViewController life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self configureNotifications];
    [self configureTableView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self.messageToolbarController stopSpeaking];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self contentChanged];
    }];
}

#pragma mark - Configuration

- (void)configureNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contentChanged)
                                                 name:MCLDisplayModeChangedNotification
                                               object:nil];
}

- (void)configureTableView
{
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    [tableView registerClass:[MCLMessageListWidmannStyleTableViewCell class] forCellReuseIdentifier:MCLMessageListWidmannStyleTableViewCellIdentifier];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    tableView.rowHeight = UITableViewAutomaticDimension;
    tableView.estimatedRowHeight = UITableViewAutomaticDimension;
    tableView.backgroundColor = [self.bag.themeManager.currentTheme backgroundColor];
    tableView.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:tableView];

    NSDictionary *views = NSDictionaryOfVariableBindings(tableView);
    [self.view addConstraints:@"H:|[tableView]|" views:views];
    [self.view addConstraints:@"V:|[tableView]|" views:views];

    self.tableView = tableView;
}

#pragma mark - Data methods

- (void)selectInitialMessage
{
    BOOL jumpToLatestPostSetting = [self.bag.settings isSettingActivated:MCLSettingJumpToLatestPost];

    // If a message to jump was defined
    if (self.jumpToMessageId) {
        [self.messages enumerateObjectsUsingBlock:^(MCLMessage *message, NSUInteger key, BOOL *stop) {
            if (self.jumpToMessageId == message.messageId) {
                NSIndexPath *jumpToMessageIndexPath = [NSIndexPath indexPathForRow:key inSection:0];
                [self.tableView scrollToRowAtIndexPath:jumpToMessageIndexPath
                                      atScrollPosition:UITableViewScrollPositionTop
                                              animated:YES];
                *stop = YES;
            }
        }];
    }
    // If new thread select first message
    else if (!self.thread.isRead) {
        NSIndexPath *firstMessageIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView selectRowAtIndexPath:firstMessageIndexPath
                                    animated:YES
                              scrollPosition:UITableViewScrollPositionTop];
        [self tableView:self.tableView didSelectRowAtIndexPath:firstMessageIndexPath];
    }
    // if jump to latest post feature enabled and last message is unread selected latest message
    else if (jumpToLatestPostSetting && !self.thread.lastMessageIsRead && [self.thread.lastMessageId intValue] > 0) {
        [self.messages enumerateObjectsUsingBlock:^(MCLMessage *message, NSUInteger key, BOOL *stop) {
            if (self.thread.lastMessageId == message.messageId) {
                NSIndexPath *latestMessageIndexPath = [NSIndexPath indexPathForRow:key inSection:0];
                UITableViewCell *latestMessageCell = [self.tableView cellForRowAtIndexPath:latestMessageIndexPath];
                if ([self.tableView.visibleCells containsObject:latestMessageCell]) {
                    [self.tableView selectRowAtIndexPath:latestMessageIndexPath
                                                animated:YES
                                          scrollPosition:UITableViewScrollPositionTop];
                    [self tableView:self.tableView didSelectRowAtIndexPath:latestMessageIndexPath];
                } else {
                    self.jumpToMessageId = self.thread.lastMessageId;
                    [self.tableView scrollToRowAtIndexPath:latestMessageIndexPath
                                          atScrollPosition:UITableViewScrollPositionTop
                                                  animated:YES];
                }

                self.thread.lastMessageRead = YES;
                *stop = YES;
            }
        }];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.messages count];
}

- (MCLMessage *)nextMessageForIndexPath:(NSIndexPath *)indexPath
{
    MCLMessage *nextMessage = nil;
    if (indexPath.row < ([self.messages count] - 1)) {
        nextMessage = self.messages[indexPath.row + 1];
    }

    return nextMessage;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *selectedIndexPath = [tableView indexPathForSelectedRow];
    BOOL isActive = selectedIndexPath ? indexPath.row == selectedIndexPath.row : NO;

    MCLMessage *message = self.messages[indexPath.row];
    message.board = self.board;
    message.boardId = self.board.boardId;
    message.thread = self.thread;

    MCLMessageListWidmannStyleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MCLMessageListWidmannStyleTableViewCellIdentifier];
    cell.indexPath = indexPath;
    cell.loginManager = self.bag.loginManager;
    cell.bag = self.bag;
    cell.dateFormatter = self.dateFormatter;
    cell.active = isActive;
    if (isActive && self.selectedCellHeight) {
        cell.webViewHeightConstraint.constant = self.selectedCellHeight;
    }
    cell.nextMessage = [self nextMessageForIndexPath:indexPath];
    cell.message = message;
    cell.delegate = self;
    [cell.toolbar updateBarButtons];

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)jumpToMessage
{
    [self.messages enumerateObjectsUsingBlock:^(MCLMessage *message, NSUInteger key, BOOL *stop) {
        if (self.jumpToMessageId == message.messageId) {
            NSIndexPath *latestMessageIndexPath = [NSIndexPath indexPathForRow:key inSection:0];
            [self.tableView selectRowAtIndexPath:latestMessageIndexPath
                                        animated:YES
                                  scrollPosition:UITableViewScrollPositionTop];
            [self tableView:self.tableView didSelectRowAtIndexPath:latestMessageIndexPath];
            self.jumpToMessageId = nil;
            *stop = YES;
        }
    }];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self jumpToMessage];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    for (MCLMessageListWidmannStyleTableViewCell *cell in self.tableView.visibleCells) {
        [cell.webView setNeedsLayout];
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MCLMessageListWidmannStyleTableViewCell *cell = (MCLMessageListWidmannStyleTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    if (![cell isSelected]) {
        return indexPath;
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView.delegate tableView:tableView didDeselectRowAtIndexPath:indexPath];

    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MCLMessageListWidmannStyleTableViewCell *cell = (MCLMessageListWidmannStyleTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    cell.backgroundColor = [self.bag.themeManager.currentTheme messageBackgroundColor];

    MCLMessage *message = self.messages[indexPath.row];
    message.board = self.board;
    message.thread = self.thread;
    if (message.text) {
        [self putMessage:message toCell:cell atIndexPath:indexPath];
    } else {
        [[[MCLMessageRequest alloc] initWithClient:self.bag.httpClient message:message] loadWithCompletionHandler:^(NSError *error, NSArray *json) {
            if (error) {
                [tableView deselectRowAtIndexPath:indexPath animated:NO];
                [tableView.delegate tableView:tableView didDeselectRowAtIndexPath:indexPath];
                [self presentError:error];
                return;
            }

            if (!message.isRead) {
                [cell markRead];
                [self.bag.notificationManager.history removeMessageId:message.messageId];
                self.thread.messagesRead = [NSNumber numberWithInteger:[self.thread.messagesRead intValue] + 1];
                message.read = YES;
                NSNumber *lastMessageId = self.thread.lastMessageId;
                if (lastMessageId && [message.messageId isEqualToNumber:lastMessageId]) {
                    self.thread.lastMessageRead = YES;
                }
            }
            [self.delegate messageListViewController:self didReadMessageOnThread:self.thread];
            [self putMessage:message toCell:cell atIndexPath:indexPath];
        }];
    }
}

- (void)putMessage:(MCLMessage *)message toCell:(MCLMessageListWidmannStyleTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    self.messageToolbarController.toolbar = cell.toolbar;
    cell.toolbar.messageToolbarDelegate = self.messageToolbarController;
    message.nextMessage = [self nextMessageForIndexPath:indexPath];
    [cell initWebviewWithMessage:message];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:NO];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MCLMessageListWidmannStyleTableViewCell *cell = (MCLMessageListWidmannStyleTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    cell.backgroundColor = [self.bag.themeManager.currentTheme tableViewCellBackgroundColor];
    [cell deinitWebview];
    [cell.toolbar setHidden:YES];

    [self.messageToolbarController stopSpeaking];
    [self updateTableView];
}

- (void)updateTableView
{
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    MCLMessageListWidmannStyleTableViewCell *cell = (MCLMessageListWidmannStyleTableViewCell *)[self.tableView cellForRowAtIndexPath:selectedIndexPath];
    [cell.toolbar setHidden:NO];
    [cell contentHeightWithCompletion:^(CGFloat height) {
        self.selectedCellHeight = height;
        cell.webViewHeightConstraint.constant = height;
        [self updateTableView];
    }];
}

#pragma mark - MCLMessageListWidmannStyleTableViewCellDelegate

- (void)contentChanged
{
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    MCLMessageListWidmannStyleTableViewCell *cell = (MCLMessageListWidmannStyleTableViewCell *)[self.tableView cellForRowAtIndexPath:selectedIndexPath];
    [cell contentHeightWithCompletion:^(CGFloat height) {
        cell.webViewHeightConstraint.constant = height;
        [self updateTableView];
    }];
}

#pragma mark - Notifications

- (void)themeChanged:(NSNotification *)notification
{
    [super themeChanged:notification];

    self.tableView.backgroundColor = [self.bag.themeManager.currentTheme backgroundColor];

    if (notification) {
        [self.tableView reloadData];
    }
}

@end

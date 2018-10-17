//
//  MCLMessageListFrameStyleViewController.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLMessageListFrameStyleViewController.h"

#import "UIView+addConstraints.h"
#import "UIViewController+Additions.h"
#import "MCLDependencyBag.h"
#import "MCLNotificationManager.h"
#import "MCLSettings.h"
#import "MCLRouter.h"
#import "MCLMessageRequest.h"
#import "MCLLogin.h"
#import "MCLBoardListTableViewController.h"
#import "MCLProfileTableViewController.h"
#import "MCLThemeManager.h"
#import "MCLPacmanLoadingView.h"
#import "MCLMessageListFrameStyleTableViewCell.h"
#import "MCLBoard.h"
#import "MCLThread.h"
#import "MCLMessage.h"
#import "MCLUser.h"
#import "MCLNotificationHistory.h"
#import "MCLMessageToolbarController.h"
#import "MCLMessageToolbar.h"


@interface MCLMessageListFrameStyleViewController ()

@property (nonatomic) CGFloat topFrameHeight;
@property (strong, nonatomic) WKWebView *webView;

@end

@implementation MCLMessageListFrameStyleViewController

#pragma mark - Initializers

- (instancetype)init
{
    // Load nib
    self = [self initWithNibName:@"MCLMessageListFrameStyleView" bundle:nil];
    if (!self) return nil;

    [self initialize];

    return self;
}

#pragma mark - ViewController life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self configureWebView];
    [self configureToolbar];
    [self configureTableView];
}

- (void)showLoadingScreenOnTopFrame
{
    [self.webView loadHTMLString:@"" baseURL:nil];

    MCLPacmanLoadingView *loadingView = [[MCLPacmanLoadingView alloc] initWithTheme:self.bag.themeManager.currentTheme];
    loadingView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.webView addSubview:loadingView];

    NSDictionary *views = NSDictionaryOfVariableBindings(loadingView);
    [self.webView addConstraints:@"V:|-44-[loadingView]|" views:views];
    [self.webView addConstraints:@"H:|[loadingView]|" views:views];
}

- (void)removeLoadingScreenOnTopFrame
{
    for (id subview in self.webView.subviews) {
        if ([[subview class] isSubclassOfClass: [MCLPacmanLoadingView class]]) {
            [subview removeFromSuperview];
        }
    }
}

- (void)configureToolbar
{
    self.toolbar.login = self.bag.login;
    self.toolbar.messageToolbarDelegate = self.messageToolbarController;
    [self.toolbar deactivateBarButtons];

    [self.toolbar addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                            action:@selector(handleToolbarDrag:)]];

    self.toolbarBottomBorderViewHeightConstraint.constant = 0.5f;
    self.toolbarBottomBorderView.backgroundColor = [self.bag.themeManager.currentTheme tableViewSeparatorColor];
}

- (void)configureTableView
{
    UINib *messageCellNib = [UINib nibWithNibName: @"MCLMessageListFrameStyleTableViewCell" bundle: nil];
    [self.tableView registerNib: messageCellNib forCellReuseIdentifier:MCLMessageListFrameStyleTableViewCellIdentifier];

    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = UITableViewAutomaticDimension;
}

- (void)configureWebView
{
    self.webView = [[WKWebView alloc] init];
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    self.webView.navigationDelegate = self;
    self.webView.scrollView.scrollsToTop = NO;
    self.webView.opaque = NO;

    [self.topFrame addSubview:self.webView];

    UIToolbar *toolbar = self.toolbar;
    UIView *toolbarBottomBorderView = self.toolbarBottomBorderView;
    WKWebView *webView = self.webView;
    NSDictionary *views = NSDictionaryOfVariableBindings(toolbar, webView, toolbarBottomBorderView);
    [self.topFrame addConstraints:@"V:|[webView][toolbar][toolbarBottomBorderView]|" views:views];
    [self.topFrame addConstraints:@"H:|[webView]|" views:views];
}

- (void)handleToolbarDrag:(UIPanGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        self.topFrameHeight = self.topFrameHeightConstraint.constant;
    }

    CGPoint translation = [gestureRecognizer translationInView:self.view];
    CGFloat screenHeight = UIScreen.mainScreen.bounds.size.height;
    CGFloat newHeight = self.topFrameHeight + translation.y;
    if (newHeight > 150) {
        if (newHeight > screenHeight) {
            newHeight = screenHeight;
        }
        self.topFrameHeightConstraint.constant = newHeight;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self.messageToolbarController stopSpeaking];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.messages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id <MCLTheme> currenTheme = self.bag.themeManager.currentTheme;
    MCLMessage *message = [self messageForIndexPath:indexPath];
    message.board = self.board;
    message.boardId = self.board.boardId;
    message.thread = self.thread;

    MCLMessageListFrameStyleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MCLMessageListFrameStyleTableViewCellIdentifier
                                                                                  forIndexPath:indexPath];

    [cell setBoardId:self.board.boardId];
    [cell setMessageId:message.messageId];

    UIView *backgroundView = [[UIView alloc] initWithFrame:cell.frame];
    backgroundView.backgroundColor = [currenTheme tableViewCellSelectedBackgroundColor];
    cell.selectedBackgroundView = backgroundView;

    cell.messageIndentionImageView.image = [cell.messageIndentionImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    cell.messageIndentionImageView.tintColor = [currenTheme tableViewSeparatorColor];

    cell.messageIndentionView.backgroundColor = cell.backgroundColor;
    [self indentView:cell.indentionConstraint withLevel:message.level];

    cell.messageIndentionImageView.hidden = (indexPath.row == 0);

    cell.messageSubjectLabel.text = message.subject;
    cell.messageSubjectLabel.textColor = [currenTheme textColor];

    cell.messageUsernameLabel.text = message.username;
    if ([message.username isEqualToString:self.bag.login.username]) {
        cell.messageUsernameLabel.textColor = [currenTheme ownUsernameTextColor];
    } else if (message.isMod) {
        cell.messageUsernameLabel.textColor = [currenTheme modTextColor];
    } else {
        cell.messageUsernameLabel.textColor = [currenTheme usernameTextColor];
    }

    cell.messageDateLabel.text = [self.dateFormatter stringFromDate:message.date];
    cell.messageDateLabel.textColor = [currenTheme detailTextColor];

    if (indexPath.row == 0 || message.isRead) {
        [cell markRead];
    } else {
        [cell markUnread];
    }

    return cell;
}

- (void)indentView:(NSLayoutConstraint *)indentionConstraint withLevel:(NSNumber *)level
{
    int indention = 10;
    indentionConstraint.constant = 0 + (indention * [level integerValue]);
}

#pragma mark - UITableViewDelegate

- (void)selectMessageWithId:(NSNumber *)selectMessageId
{
    [self.messages enumerateObjectsUsingBlock:^(MCLMessage *message, NSUInteger key, BOOL *stop) {
        if (selectMessageId == message.messageId) {
            NSIndexPath *latestMessageIndexPath = [NSIndexPath indexPathForRow:key inSection:0];
            [self.tableView selectRowAtIndexPath:latestMessageIndexPath
                                        animated:YES
                                  scrollPosition:UITableViewScrollPositionTop];
            [self tableView:self.tableView didSelectRowAtIndexPath:latestMessageIndexPath];
            *stop = YES;
        }
    }];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    NSNumber *messageId = self.jumpToMessageId ? self.jumpToMessageId : self.thread.lastMessageId;
    [self selectMessageWithId:messageId];
}

- (MCLMessage *)messageForIndexPath:(NSIndexPath *)indexPath
{
    NSInteger i = indexPath.row;
    MCLMessage *message = self.messages[i];
    message.board = self.board;
    message.thread = self.thread;
    if (indexPath.row < ([self.messages count] - 1)) {
        message.nextMessage = self.messages[i + 1];
    }

    return message;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.toolbar deactivateBarButtons];
    MCLMessageListFrameStyleTableViewCell *cell = (MCLMessageListFrameStyleTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    MCLMessage *message = [self messageForIndexPath:indexPath];

    if (message.text) {
        [self loadMessage:message fromCell:cell];
        return;
    }

    [self showLoadingScreenOnTopFrame];

    MCLMessageRequest *request = [[MCLMessageRequest alloc] initWithClient:self.bag.httpClient message:message];
    [request loadWithCompletionHandler:^(NSError *error, NSArray *json) {
        [self removeLoadingScreenOnTopFrame];

        if (error) {
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
        [self loadMessage:message fromCell:cell];
    }];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.messageToolbarController stopSpeaking];
}

- (void)loadMessage:(MCLMessage *)message fromCell:(MCLMessageListFrameStyleTableViewCell *)cell
{
    cell.messageText = message.text;
    NSString *messageText = [message messageHtmlWithTopMargin:15
                                                        theme:self.bag.themeManager.currentTheme
                                                     settings:self.bag.settings];
    [self.webView loadHTMLString:messageText baseURL:nil];
    [self.toolbar updateBarButtonsWithMessage:message];
}

#pragma mark - Notifications

- (void)themeChanged:(NSNotification *)notification
{
    [super themeChanged:notification];

    self.view.backgroundColor = [self.bag.themeManager.currentTheme backgroundColor];
    self.tableView.backgroundColor = [self.bag.themeManager.currentTheme backgroundColor];

    if (notification) {
        NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
        [self.tableView selectRowAtIndexPath:selectedIndexPath
                                    animated:NO
                              scrollPosition:UITableViewScrollPositionNone];
        [self tableView:self.tableView didSelectRowAtIndexPath:selectedIndexPath];

        [self.tableView reloadData];
    }
}

@end

//
//  MCLMessageListFrameStyleViewController.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
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
#import "MCLLoginManager.h"
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
    self.toolbar.loginManager = self.bag.loginManager;
    self.toolbar.messageToolbarDelegate = self.messageToolbarController;
    self.messageToolbarController.toolbar = self.toolbar;
    [self.toolbar deactivateBarButtons];

    [self.toolbar addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                            action:@selector(handleToolbarDrag:)]];

    self.toolbarBottomBorderViewHeightConstraint.constant = 0.5f;
    self.toolbarBottomBorderView.backgroundColor = [self.bag.themeManager.currentTheme tableViewSeparatorColor];
}

- (void)configureTableView
{
    UINib *messageCellNib = [UINib nibWithNibName: @"MCLMessageListFrameStyleTableViewCell" bundle: nil];
    [self.tableView registerNib:messageCellNib forCellReuseIdentifier:MCLMessageListFrameStyleTableViewCellIdentifier];

    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = UITableViewAutomaticDimension;
}

- (void)configureWebView
{
    WKWebViewConfiguration *webViewConfig = [[WKWebViewConfiguration alloc] init];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
        webViewConfig.dataDetectorTypes = WKDataDetectorTypeLink;
    }
    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:webViewConfig];
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
    MCLMessageListFrameStyleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MCLMessageListFrameStyleTableViewCellIdentifier
                                                                                  forIndexPath:indexPath];

    MCLMessage *message = [self messageForIndexPath:indexPath];
    if (!message) {
        return cell;
    }
    message.board = self.board;
    message.boardId = self.board.boardId;
    message.thread = self.thread;

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

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.hyphenationFactor = 1.0f;
    NSDictionary<NSAttributedStringKey, id> *subjectParagraphAttributes = @{ NSParagraphStyleAttributeName: paragraphStyle,
                                                                             NSForegroundColorAttributeName: [currenTheme textColor] };
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:message.subject
                                                                                         attributes:subjectParagraphAttributes];
    cell.messageSubjectLabel.attributedText = attributedString;

    cell.messageUsernameLabel.text = message.username;
    if ([message.username isEqualToString:self.bag.loginManager.username]) {
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
    int indention = 15;
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    CGFloat maxWidth = screenWidth - screenWidth * 0.2;
    CGFloat newVal = 0 + (indention * [level integerValue]);

    indentionConstraint.constant = newVal > maxWidth ? maxWidth : newVal;
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
    if (self.selectAfterScroll) {
        NSNumber *messageId = self.jumpToMessageId ? self.jumpToMessageId : self.thread.lastMessageId;
        [self selectMessageWithId:messageId];
        self.selectAfterScroll = NO;
    }
}

- (MCLMessage *)messageForIndexPath:(NSIndexPath *)indexPath
{
    NSInteger i = indexPath.row;
    if (i >= [self.messages count]) {
        return nil;
    }
    MCLMessage *message = self.messages[i];
    message.board = self.board;
    message.thread = self.thread;
    if (i < ([self.messages count] - 1)) {
        message.nextMessage = self.messages[i + 1];
    }

    return message;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.toolbar deactivateBarButtons];
    MCLMessageListFrameStyleTableViewCell *cell = (MCLMessageListFrameStyleTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    MCLMessage *message = [self messageForIndexPath:indexPath];

    if (!message) {
        return;
    }

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

            // Workaround to fix read status on cell not updating after scrolling (jump to latest post + keyboard shortcuts)
            [UIView animateWithDuration:0 animations:^{
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            } completion:^(BOOL finished) {
                [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }];
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
    int topMargin = 15;
    if (SYSTEM_VERSION_LESS_THAN(@"10.0")) {
        topMargin += 70;
    }
    NSString *messageText = [message messageHtmlWithTopMargin:topMargin
                                                        width:cell.contentView.bounds.size.width
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
        if (selectedIndexPath) {
            [self.tableView selectRowAtIndexPath:selectedIndexPath
                                        animated:NO
                                  scrollPosition:UITableViewScrollPositionNone];
            [self tableView:self.tableView didSelectRowAtIndexPath:selectedIndexPath];
        }
        [self.tableView reloadData];
    }
}

@end

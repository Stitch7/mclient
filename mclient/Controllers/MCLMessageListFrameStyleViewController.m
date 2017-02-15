//
//  MCLMessageListFrameStyleViewController.m
//  mclient
//
//  Created by Christopher Reitz on 16.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLMessageListFrameStyleViewController.h"

#import "constants.h"
#import "UIView+addConstraints.h"
#import "KeychainItemWrapper.h"
#import "Reachability.h"
#import "MCLAppDelegate.h"
#import "MCLMServiceConnector.h"
#import "MCLBoardListTableViewController.h"
#import "MCLProfileTableViewController.h"
#import "MCLDetailView.h"
#import "MCLMServiceErrorView.h"
#import "MCLInternetConnectionErrorView.h"
#import "MCLLoadingView.h"
#import "MCLMessageListFrameStyleTableViewCell.h"
#import "MCLBoard.h"
#import "MCLThread.h"
#import "MCLMessage.h"

@interface MCLMessageListFrameStyleViewController ()

@property (strong, nonatomic) AVSpeechSynthesizer *speechSynthesizer;
@property (strong) NSMutableArray *messages;
@property (strong) NSString *username;
@property (strong) NSString *password;
@property (assign) BOOL validLogin;
@property (strong) NSDateFormatter *dateFormatter;
@property (strong) UIRefreshControl *refreshControl;

@property (nonatomic, retain) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIView *topFrame;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topFrameHeightConstraint;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIView *bottomFrame;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolbarButtonSpeak;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolbarButtonNotification;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolbarButtonEdit;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolbarButtonReply;

@property (nonatomic) CGFloat topFrameHeight;
@property (assign, nonatomic) UIInterfaceOrientation orientationBeforeWentToBackground;
@property (strong, nonatomic) WKWebView *webView;

@end

@implementation MCLMessageListFrameStyleViewController

#pragma mark - ViewController

- (void)awakeFromNib
{
    [super awakeFromNib];

    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:identifier accessGroup:nil];
    self.username = [keychainItem objectForKey:(__bridge id)(kSecAttrAccount)];
    NSData *passwordData = [keychainItem objectForKey:(__bridge id)(kSecValueData)];
    self.password = [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];

    self.validLogin = [[NSUserDefaults standardUserDefaults] boolForKey:@"validLogin"];

    // Init + setup dateformatter for message dates
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDoesRelativeDateFormatting:YES];
    [self.dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [self.dateFormatter setTimeStyle:NSDateFormatterShortStyle];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self configureContainerView];
    [self configureWebView];
    [self configureToolbar];
    [self configureTableView];
    [self loadData];
}

-(void)loadData
{
    if (!self.board || !self.thread) {
        [self.view addSubview:[[MCLDetailView alloc] initWithFrame:self.view.bounds]];
        return;
    }

    [self updateTitle:self.thread.subject];

    // Add loading view
    [self.view addSubview:[[MCLLoadingView alloc] initWithFrame:self.view.frame]];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    // Load data async
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *mServiceError;
        NSDictionary *loginData;
        if (self.validLogin) {
            loginData = @{@"username":self.username, @"password":self.password};
        }
        NSDictionary *data = [[MCLMServiceConnector sharedConnector] threadWithId:self.thread.threadId
                                                                      fromBoardId:self.board.boardId
                                                                            login:loginData
                                                                            error:&mServiceError];
        // Process data on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [self fetchedData:data error:mServiceError];
            if (!mServiceError) {
                NSNumber *lastMessageId = self.thread.lastMessageId;
                BOOL firstMessageIsRead = self.thread.isRead;
                BOOL jumpToLatestPost = [[NSUserDefaults standardUserDefaults] boolForKey:@"jumpToLatestPost"];
                BOOL lastMessageExists = lastMessageId > 0;
                BOOL lastMessageIsNotRead = !self.thread.lastMessageIsRead;

                if (firstMessageIsRead && jumpToLatestPost && lastMessageExists && lastMessageIsNotRead) {
                    [self.messages enumerateObjectsUsingBlock:^(MCLMessage *message, NSUInteger key, BOOL *stop) {
                        if (self.thread.lastMessageId == message.messageId) {
                            NSIndexPath *latestMessageIndexPath = [NSIndexPath indexPathForRow:key inSection:0];
                            [self.tableView scrollToRowAtIndexPath:latestMessageIndexPath
                                                  atScrollPosition:UITableViewScrollPositionTop
                                                          animated:YES];
                            self.thread.lastMessageRead = YES;
                        }
                    }];
                }
                // Select first message
                else {
                    NSIndexPath *indexPathOfFirstMessage = [NSIndexPath indexPathForRow:0 inSection:0];
                    [self.tableView selectRowAtIndexPath:indexPathOfFirstMessage
                                                animated:NO
                                          scrollPosition:UITableViewScrollPositionNone];
                    [self tableView:self.tableView didSelectRowAtIndexPath:indexPathOfFirstMessage];
                }
            }
        });
    });

}

- (void)configureContainerView
{
    [[NSBundle mainBundle] loadNibNamed:@"MCLMessageListFrameStyleView" owner:self options:nil];
    self.containerView.frame = self.view.frame;
    [self.view addSubview:self.containerView];
}

- (void)configureToolbar
{
    [self.toolbar addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                            action:@selector(handleToolbarDrag:)]];
}

- (void)configureTableView
{
    UINib *threadCellNib = [UINib nibWithNibName: @"MCLMessageListFrameStyleTableViewCell" bundle: nil];
    [self.tableView registerNib: threadCellNib forCellReuseIdentifier: @"MessageCell"];

    // Add refresh control
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];

    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;
    tableViewController.refreshControl = self.refreshControl;
}

- (void)configureWebView
{
    self.webView = [[WKWebView alloc] init];
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    self.webView.navigationDelegate = self;
    self.webView.scrollView.scrollsToTop = NO;
    self.webView.opaque = NO;

    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    CGFloat navigationBarHeight = self.navigationController.navigationBar.frame.size.height;
    self.webView.scrollView.contentInset = UIEdgeInsetsMake(statusBarHeight + navigationBarHeight, 0.0f, 0.0f, 0.0f);

    [self.topFrame addSubview:self.webView];

    UIToolbar *toolbar = self.toolbar;
    WKWebView *webView = self.webView;
    NSDictionary *views = NSDictionaryOfVariableBindings(toolbar, webView);

    [self.topFrame addConstraints:@"V:|[webView][toolbar]|" views:views];
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

    if (self.speechSynthesizer.speaking) {
        [self.speechSynthesizer stopSpeakingAtBoundary:AVSpeechBoundaryWord];
        self.toolbarButtonSpeak.image = [UIImage imageNamed:@"speakButton.png"];
    }
}

#pragma mark - Data methods

- (void)loadThread:(MCLThread *)inThread fromBoard:(MCLBoard *)inBoard
{
    self.thread = inThread;
    self.board = inBoard;

    // Set title
    [self updateTitle:inThread.subject];

    // Close thread list in portrait mode
    if (self.masterPopoverController) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }

    // Visualize loading
    MCLLoadingView *loadingView = [[MCLLoadingView alloc] initWithFrame:self.view.frame];
    
    [self.view addSubview:loadingView];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    // Load data async
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *mServiceError;
        NSDictionary *loginData;
        if (self.validLogin) {
            loginData = @{@"username":self.username, @"password":self.password};
        }
        NSDictionary *data = [[MCLMServiceConnector sharedConnector] threadWithId:self.thread.threadId
                                                                      fromBoardId:self.board.boardId
                                                                            login:loginData
                                                                            error:&mServiceError];
        // Process data on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [self fetchedData:data error:mServiceError];

            // Scrool table to top
            [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];

            if (!mServiceError) {
                NSNumber *lastMessageId = self.thread.lastMessageId;
                BOOL firstMessageIsRead = self.thread.isRead;
                BOOL jumpToLatestPost = [[NSUserDefaults standardUserDefaults] boolForKey:@"jumpToLatestPost"];
                BOOL lastMessageExists = lastMessageId > 0;
                BOOL lastMessageIsNotRead = !self.thread.lastMessageIsRead;

                if (firstMessageIsRead && jumpToLatestPost && lastMessageExists && lastMessageIsNotRead) {
                    [self.messages enumerateObjectsUsingBlock:^(MCLMessage *message, NSUInteger key, BOOL *stop) {
                        if (self.thread.lastMessageId == message.messageId) {
                            NSIndexPath *latestMessageIndexPath = [NSIndexPath indexPathForRow:key inSection:0];
                            [self.tableView scrollToRowAtIndexPath:latestMessageIndexPath
                                                  atScrollPosition:UITableViewScrollPositionTop
                                                          animated:YES];
                            self.thread.lastMessageRead = YES;
                        }
                    }];
                }
                // Select first message
                else {
                    NSIndexPath *indexPathOfFirstMessage = [NSIndexPath indexPathForRow:0 inSection:0];
                    [self.tableView selectRowAtIndexPath:indexPathOfFirstMessage
                                                animated:NO
                                          scrollPosition:UITableViewScrollPositionNone];
                    [self tableView:self.tableView didSelectRowAtIndexPath:indexPathOfFirstMessage];
                }
            }
        });
    });
}

- (void)reloadData
{
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *mServiceError;
        NSDictionary *loginData;
        if (self.validLogin) {
            loginData = @{@"username":self.username, @"password":self.password};
        }
        NSDictionary *data = [[MCLMServiceConnector sharedConnector] threadWithId:self.thread.threadId
                                                                      fromBoardId:self.board.boardId
                                                                            login:loginData
                                                                            error:&mServiceError];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self fetchedData:data error:mServiceError];
            [self.refreshControl endRefreshing];

            [self.tableView selectRowAtIndexPath:selectedIndexPath
                                        animated:NO
                                  scrollPosition:UITableViewScrollPositionNone];
            [self tableView:self.tableView didSelectRowAtIndexPath:selectedIndexPath];
        });
    });
}

- (void)fetchedData:(NSDictionary *)data error:(NSError *)error
{
    for (id subview in self.view.subviews) {
        if ([[subview class] isSubclassOfClass: [MCLErrorView class]] ||
            [[subview class] isSubclassOfClass: [MCLLoadingView class]] ||
            [[subview class] isSubclassOfClass: [MCLDetailView class]]
        ) {
            [subview removeFromSuperview];
        }
    }
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    if (error) {
        switch (error.code) {
            case -2:
                [self.view addSubview:[[MCLInternetConnectionErrorView alloc] initWithFrame:self.view.frame
                                                                               hideSubLabel:YES]];
                break;

            default:
                [self.view addSubview:[[MCLMServiceErrorView alloc] initWithFrame:self.view.frame
                                                                          andText:[error localizedDescription]
                                                                     hideSubLabel:YES]];
                break;
        }
    } else {
        self.messages = [NSMutableArray array];

        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        [dateFormatter setLocale:enUSPOSIXLocale];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];

        for (id object in data) {
            NSNumber *messageId = [object objectForKey:@"messageId"];
            id isReadOpt = [object objectForKey:@"isRead"];
            BOOL isRead = (isReadOpt != (id)[NSNull null] && isReadOpt != nil) ? [isReadOpt boolValue] : YES;
            NSNumber *level = [object objectForKey:@"level"];
            BOOL mod = [[object objectForKey:@"mod"] boolValue];
            NSString *username = [object objectForKey:@"username"];
            NSString *subject = [object objectForKey:@"subject"];
            NSDate *date = [dateFormatter dateFromString:[object objectForKey:@"date"]];

            MCLMessage *message = [MCLMessage messageWithId:messageId
                                                       read:isRead
                                                      level:level
                                                        mod:mod
                                                   username:username
                                                    subject:subject
                                                       date:date];
            [self.messages addObject:message];
        }

        [self.tableView reloadData];
    }
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.messages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger i = indexPath.row;

    MCLMessage *message = self.messages[i];
    MCLMessage *nextMessage = nil;
    if (indexPath.row < ([self.messages count] - 1)) {
        nextMessage = self.messages[i + 1];
    }

    static NSString *cellIdentifier = @"MessageCell";
    MCLMessageListFrameStyleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];

    [cell setBoardId:self.board.boardId];
    [cell setMessageId:message.messageId];

    UIView *backgroundView = [[UIView alloc] initWithFrame:cell.frame];
    backgroundView.backgroundColor = [self.currentTheme tableViewCellSelectedBackgroundColor];
    cell.selectedBackgroundView = backgroundView;

    cell.messageIndentionImageView.image = [cell.messageIndentionImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    cell.messageIndentionImageView.tintColor = [self.currentTheme tableViewSeparatorColor];

    cell.messageIndentionView.backgroundColor = cell.backgroundColor;
    [self indentView:cell.indentionConstraint withLevel:message.level];

    cell.messageIndentionImageView.hidden = (i == 0);

    cell.messageSubjectLabel.text = message.subject;
    cell.messageSubjectLabel.textColor = [self.currentTheme textColor];

    cell.messageUsernameLabel.text = message.username;
    if ([message.username isEqualToString:self.username]) {
        cell.messageUsernameLabel.textColor = [self.currentTheme ownUsernameTextColor];
    } else if (message.isMod) {
        cell.messageUsernameLabel.textColor = [self.currentTheme modTextColor];
    } else {
        cell.messageUsernameLabel.textColor = [self.currentTheme usernameTextColor];
    }

    cell.messageDateLabel.text = [self.dateFormatter stringFromDate:message.date];
    cell.messageDateLabel.textColor = [self.currentTheme detailTextColor];

    if (i == 0 || message.isRead) {
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


-(void)barButton:(UIBarButtonItem *)barButton hide:(BOOL)hide
{
    if (hide) {
        [barButton setEnabled:NO];
        [barButton setTintColor: [UIColor clearColor]];
    } else {
        [barButton setEnabled:YES];
        [barButton setTintColor:nil];
    }
}

#pragma mark - UITableViewDelegate

- (void)selectLastMessage
{
    [self.messages enumerateObjectsUsingBlock:^(MCLMessage *message, NSUInteger key, BOOL *stop) {
        if (self.thread.lastMessageId == message.messageId) {
            NSIndexPath *latestMessageIndexPath = [NSIndexPath indexPathForRow:key inSection:0];
            [self.tableView selectRowAtIndexPath:latestMessageIndexPath
                                        animated:YES
                                  scrollPosition:UITableViewScrollPositionTop];
            [self tableView:self.tableView didSelectRowAtIndexPath:latestMessageIndexPath];
        }
    }];
}

-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self selectLastMessage];
}

- (NSString *)messageHtml:(MCLMessage *)message
{
    NSString *messageHtml = @"";
    switch ([[NSUserDefaults standardUserDefaults] integerForKey:@"showImages"]) {
        case kMCLSettingsShowImagesAlways:
        default:
            messageHtml = message.textHtmlWithImages;
            break;

        case kMCLSettingsShowImagesWifi: {
            Reachability *wifiReach = [Reachability reachabilityForLocalWiFi];
            messageHtml = [wifiReach currentReachabilityStatus] == ReachableViaWiFi
                ? message.textHtmlWithImages
                : message.textHtml;
            break;
        }
        case kMCLSettingsShowImagesNever:
            messageHtml = message.textHtml;
            break;
    }

    return [MCLMessageListViewController messageHtmlSkeletonForHtml:messageHtml
                                                      withTopMargin:10
                                                           andTheme:self.currentTheme];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger i = indexPath.row;

    MCLMessageListFrameStyleTableViewCell *cell = (MCLMessageListFrameStyleTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];

    MCLMessage *message = self.messages[i];
    MCLMessage *nextMessage = nil;
    if (indexPath.row < ([self.messages count] - 1)) {
        nextMessage = self.messages[i + 1];
    }

    self.toolbarButtonNotification.image = [UIImage imageNamed:@"notificationButtonDisabled.png"];
    BOOL hideNotificationButton = !self.validLogin || ![message.username isEqualToString:self.username];
    [self barButton:self.toolbarButtonNotification hide:hideNotificationButton];

    BOOL hideEditButton = !self.validLogin || self.thread.isClosed || !([message.username isEqualToString:self.username] && nextMessage.level <= message.level);
    [self barButton:self.toolbarButtonEdit hide:hideEditButton];

    BOOL hideReplyButton = ! self.validLogin || self.thread.isClosed;
    [self barButton:self.toolbarButtonReply hide:hideReplyButton];

    if (message.text) {
        [self loadMessage:message fromCell:cell];
    } else {
        [self.webView loadHTMLString:@"" baseURL:nil];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        CGRect mvBounds = self.topFrame.bounds;
        CGFloat loadingFrameHeight = mvBounds.size.height - self.toolbar.frame.size.height - 1;
        CGRect loadingFrame = CGRectMake(mvBounds.origin.x, mvBounds.origin.y, mvBounds.size.width, loadingFrameHeight);
        [self.topFrame addSubview:[[MCLLoadingView alloc] initWithFrame:loadingFrame]];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError *mServiceError;
            NSDictionary *loginData;
            if (self.validLogin) {
                loginData = @{@"username":self.username, @"password":self.password};
            }
            NSDictionary *data = [[MCLMServiceConnector sharedConnector] messageWithId:message.messageId
                                                                           fromBoardId:self.board.boardId
                                                                           andThreadId:self.thread.threadId
                                                                                 login:loginData
                                                                                 error:&mServiceError];
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                for (id subview in self.topFrame.subviews) {
                    if ([[subview class] isSubclassOfClass: [MCLLoadingView class]]) {
                        [subview removeFromSuperview];
                    }
                }

                if (mServiceError) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                                    message:[mServiceError localizedDescription]
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                          otherButtonTitles:nil];
                    [alert show];
                }
                else {
                    message.userId = [data objectForKey:@"userId"];
                    message.text = [data objectForKey:@"text"];
                    message.textHtml = [data objectForKey:@"textHtml"];
                    message.textHtmlWithImages = [data objectForKey:@"textHtmlWithImages"];
                    if ([data objectForKey:@"notification"] != [NSNull null]) {
                        message.notification = [[data objectForKey:@"notification"] boolValue];
                    }

                    if (!message.isRead) {
                        [cell markRead];
                        self.thread.messagesRead = [NSNumber numberWithInteger:[self.thread.messagesRead intValue] + 1];
                        message.read = YES;
                        if ([message.messageId isEqualToNumber:self.thread.lastMessageId]) {
                            self.thread.lastMessageRead = YES;
                        }
                    }
                    [self.delegate messageListViewController:self didReadMessageOnThread:self.thread];
                    [self loadMessage:message fromCell:cell];
                }
            });
        });
    }
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.speechSynthesizer.speaking) {
        [self.speechSynthesizer stopSpeakingAtBoundary:AVSpeechBoundaryWord];
        self.toolbarButtonSpeak.image = [UIImage imageNamed:@"speakButton.png"];
    }
}

- (void)loadMessage:(MCLMessage *)message fromCell:(MCLMessageListFrameStyleTableViewCell *)cell
{
    cell.messageText = message.text;
    [self.webView loadHTMLString:[self messageHtml:message] baseURL:nil];

    BOOL showNotificationButton = self.validLogin && [message.username isEqualToString:self.username];
    if (showNotificationButton) {
        if (message.notification) {
            [self.toolbarButtonNotification setTag:1];
            self.toolbarButtonNotification.image = [UIImage imageNamed:@"notificationButtonEnabled.png"];
        } else {
            [self.toolbarButtonNotification setTag:0];
        }
    }
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        [UIApplication.sharedApplication openURL:navigationAction.request.URL];
        decisionHandler(WKNavigationActionPolicyCancel);
    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

#pragma mark - AVSpeechSynthesizerDelegate

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance
{
    self.toolbarButtonSpeak.image = [UIImage imageNamed:@"stopButton.png"];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance
{
    self.toolbarButtonSpeak.image = [UIImage imageNamed:@"speakButton.png"];
}


#pragma mark - MCLComposeMessageViewControllerDelegate

- (void)messageSentWithType:(NSUInteger)type
{
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *mServiceError;
        NSDictionary *loginData;
        if (self.validLogin) {
            loginData = @{@"username":self.username, @"password":self.password};
        }
        NSDictionary *data = [[MCLMServiceConnector sharedConnector] threadWithId:self.thread.threadId
                                                                      fromBoardId:self.board.boardId
                                                                            login:loginData
                                                                            error:&mServiceError];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self fetchedData:data error:mServiceError];

            if (type == kMCLComposeTypeEdit) {
                // Reload selected message
                [self.tableView selectRowAtIndexPath:selectedIndexPath
                                            animated:NO
                                      scrollPosition:UITableViewScrollPositionNone];
                [self tableView:self.tableView didSelectRowAtIndexPath:selectedIndexPath];
            }
        });
    });
}


#pragma mark - Actions

- (void)backAction
{
    [self performSegueWithIdentifier:@"PushBackToThreadList" sender:nil];
}

- (IBAction)openProfileAction:(UIBarButtonItem *)sender {
    [self performSegueWithIdentifier:@"ModalToShowProfile" sender:self];
}

- (IBAction)copyLinkAction:(UIBarButtonItem *)sender
{
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    MCLMessage *message = self.messages[selectedIndexPath.row];

    NSString *link = [NSString stringWithFormat:@"%@?mode=message&brdid=%@&msgid=%@", kManiacForumURL, self.board.boardId, message.messageId];

    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = link;

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Copied link", nil)
                                                    message:NSLocalizedString(@"URL for this message was copied to clipboard", nil)
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                          otherButtonTitles:nil];
    [alert show];
}

- (IBAction)speakAction:(UIBarButtonItem *)sender
{
    if (self.speechSynthesizer == nil) {
        self.speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
        self.speechSynthesizer.delegate = self;
    }

    if (self.speechSynthesizer.speaking) {
        [self.speechSynthesizer stopSpeakingAtBoundary:AVSpeechBoundaryWord];
        self.toolbarButtonSpeak.image = [UIImage imageNamed:@"speakButton.png"];
    } else {
        NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
        MCLMessageListFrameStyleTableViewCell *selectedCell =
            (MCLMessageListFrameStyleTableViewCell *)[self.tableView cellForRowAtIndexPath:selectedIndexPath];

        // Backup of UIWebView content because it's get manipulated by our operation below
        NSString *js1 = @"document.getElementsByTagName(\"html\")[0].innerHTML;";
        [self.webView evaluateJavaScript:js1 completionHandler:^(NSString *result, NSError *error) {
            if (error != nil) { return; }

            NSString *webviewTextBackup = result;

            // Remove quoted text (font tags)
            NSString *js2 = @"var fontTags = document.getElementsByTagName(\"font\");"
                            " for (var i=0; i < fontTags.length; x++) { fontTags[i].remove() };";
            [self.webView evaluateJavaScript:js2 completionHandler:nil];

            NSString *js3 = @"document.getElementsByTagName(\"body\")[0].textContent;";
            [self.webView evaluateJavaScript:js3 completionHandler:^(NSString *result, NSError *error) {
                if (error != nil) { return; }

                NSString *text = result;
                text = [[selectedCell.messageSubjectLabel.text  stringByAppendingString:@"..."] stringByAppendingString:text];
                text = [[NSString stringWithFormat:@"Von %@...", selectedCell.messageUsernameLabel.text] stringByAppendingString:text];

                // Restoring backuped original content
                [self.webView loadHTMLString:webviewTextBackup baseURL:nil];

                // Speak text
                AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:text];
                [utterance setVoice:[AVSpeechSynthesisVoice voiceWithLanguage:@"de-DE"]];
                
                [self.speechSynthesizer speakUtterance:utterance];

            }];

        }];
    }
}

- (IBAction)notificationAction:(UIBarButtonItem *)sender
{
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    MCLMessage *message = self.messages[selectedIndexPath.row];

    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:identifier accessGroup:nil];
    NSString *username = [keychainItem objectForKey:(__bridge id)(kSecAttrAccount)];
    NSData *passwordData = [keychainItem objectForKey:(__bridge id)(kSecValueData)];
    NSString *password = [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *mServiceError;
        [[MCLMServiceConnector sharedConnector] notificationForMessageId:message.messageId
                                                                 boardId:self.board.boardId
                                                                username:username
                                                                password:password
                                                                   error:&mServiceError];
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

            NSString *alertTitle, *alertMessage;
            if (mServiceError) {
                alertTitle = NSLocalizedString(@"Error", nil);
                alertMessage = [mServiceError localizedDescription];
            } else if (sender.tag == 1) {
                [sender setTag:0];
                self.toolbarButtonNotification.image = [UIImage imageNamed:@"notificationButtonDisabled.png"];
                alertTitle = NSLocalizedString(@"Notification disabled", nil);
                alertMessage = NSLocalizedString(@"You will no longer receive Emails if anyone replies to this message", nil);
            } else {
                [sender setTag:1];
                self.toolbarButtonNotification.image = [UIImage imageNamed:@"notificationButtonEnabled.png"];
                alertTitle = NSLocalizedString(@"Notification enabled", nil);
                alertMessage = NSLocalizedString(@"You will receive an Email if anyone replies to this message", nil);
            }

            [[[UIAlertView alloc] initWithTitle:alertTitle
                                        message:alertMessage
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                              otherButtonTitles:nil] show];
        });
    });
}

- (IBAction)editAction:(UIBarButtonItem *)sender {
    [self performSegueWithIdentifier:@"ModalToEditReply" sender:self];
}

- (IBAction)replyAction:(UIBarButtonItem *)sender {
    [self performSegueWithIdentifier:@"ModalToComposeReply" sender:self];
}

#pragma mark - Notifications

- (void)themeChanged:(NSNotification *)notification
{
    [super themeChanged:notification];

    self.view.backgroundColor = [self.currentTheme backgroundColor];

    if (notification) {
        NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
        [self.tableView selectRowAtIndexPath:selectedIndexPath
                                    animated:NO
                              scrollPosition:UITableViewScrollPositionNone];
        [self tableView:self.tableView didSelectRowAtIndexPath:selectedIndexPath];

        [self.tableView reloadData];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    self.orientationBeforeWentToBackground = [[UIApplication sharedApplication] statusBarOrientation];

    UIViewController *destinationVC = [[segue.destinationViewController viewControllers] objectAtIndex:0];
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    MCLMessage *message = self.messages[indexPath.row];

    if ([segue.identifier isEqualToString:@"ModalToComposeReply"]) {
        MCLComposeMessageViewController *composeMessageVC = (MCLComposeMessageViewController *)destinationVC;
        NSString *subject = message.subject;
        NSString *subjectReplyPrefix = @"Re:";
        if ([subject length] < 3 || ![[subject substringToIndex:3] isEqualToString:subjectReplyPrefix]) {
            subject = [subjectReplyPrefix stringByAppendingString:subject];
        }
        [composeMessageVC setDelegate:self];
        [composeMessageVC setType:kMCLComposeTypeReply];
        [composeMessageVC setBoardId:self.board.boardId];
        [composeMessageVC setThreadId:self.thread.threadId];
        [composeMessageVC setMessageId:message.messageId];
        [composeMessageVC setSubject:subject];
    }
    else if ([segue.identifier isEqualToString:@"ModalToEditReply"]) {
        MCLComposeMessageViewController *editMessageVC = (MCLComposeMessageViewController *)destinationVC;
        [editMessageVC setDelegate:self];
        [editMessageVC setType:kMCLComposeTypeEdit];
        [editMessageVC setBoardId:self.board.boardId];
        [editMessageVC setThreadId:self.thread.threadId];
        [editMessageVC setMessageId:message.messageId];
        [editMessageVC setSubject:message.subject];
        [editMessageVC setText:message.text];
    }
    else if ([segue.identifier isEqualToString:@"ModalToShowProfile"]) {
        MCLProfileTableViewController *profileVC = (MCLProfileTableViewController *)destinationVC;
        [profileVC setDelegate:self];
        [profileVC setUserId:message.userId];
        [profileVC setUsername:message.username];
    }
}

@end

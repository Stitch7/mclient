//
//  MCLMessageListWidmannStyleViewController.m
//  mclient
//
//  Created by Christopher Reitz on 25.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLMessageListWidmannStyleViewController.h"

#import "constants.h"
#import "UIView+addConstraints.h"
#import "KeychainItemWrapper.h"
#import "Reachability.h"
#import "MCLAppDelegate.h"
#import "MCLMServiceConnector.h"
#import "MCLProfileTableViewController.h"
#import "MCLDetailView.h"
#import "MCLMServiceErrorView.h"
#import "MCLInternetConnectionErrorView.h"
#import "MCLLoadingView.h"
#import "MCLMessageListWidmannStyleTableViewCell.h"
#import "MCLBoard.h"
#import "MCLThread.h"
#import "MCLMessage.h"
#import "MCLReadList.h"


@interface MCLMessageListWidmannStyleViewController ()

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSIndexPath *selectedCellIndexPath;
@property (assign, nonatomic) CGFloat selectedCellHeight;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) UIView *refreshControlBackgroundView;
@property (strong, nonatomic) UIColor *tableSeparatorColor;
@property (strong, nonatomic) NSMutableArray *messages;
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *password;
@property (assign, nonatomic) BOOL validLogin;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (assign, nonatomic) UIInterfaceOrientation orientationBeforeWentToBackground;

@end

@implementation MCLMessageListWidmannStyleViewController

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

    [self configureTableView];
    [self configureRefreshControl];
}

-(void)viewWillAppear:(BOOL)animated
{
    if (self.board && self.thread) {
        [self updateTitle:self.thread.subject];

        // Visualize loading
        [self.view addSubview:[[MCLLoadingView alloc] initWithFrame:self.view.frame]];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

        // Load data async
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError *mServiceError;
            NSDictionary *data = [[MCLMServiceConnector sharedConnector] threadWithId:self.thread.threadId
                                                                          fromBoardId:self.board.boardId
                                                                                error:&mServiceError];
            // Process data on main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                [self fetchedData:data error:mServiceError];
                // Restore tables separatorColor
                [self.tableView setSeparatorColor:self.tableSeparatorColor];
            });
        });
    } else {
        [self.view addSubview:[[MCLDetailView alloc] initWithFrame:self.view.bounds]];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (selectedIndexPath) {
        MCLMessageListWidmannStyleTableViewCell *cell =
            (MCLMessageListWidmannStyleTableViewCell *)[self.tableView cellForRowAtIndexPath:selectedIndexPath];
        if (cell.speechSynthesizer.speaking) {
            [cell.speechSynthesizer stopSpeakingAtBoundary:AVSpeechBoundaryWord];
            cell.messageSpeakButton.image = [UIImage imageNamed:@"speakButton.png"];
        }
    }
}

- (void)configureTableView
{
    UITableView *tableView = [[UITableView alloc] init];

    tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [tableView registerClass:[MCLMessageListWidmannStyleTableViewCell class] forCellReuseIdentifier:@"MessageCell"];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.backgroundColor = [UIColor whiteColor];
    tableView.scrollsToTop = YES;

    // Cache original tables separatorColor and set to clear to avoid flickering loading view
    self.tableSeparatorColor = [tableView separatorColor];
    [tableView setSeparatorColor:[UIColor clearColor]];

    [self.view addSubview:tableView];

    NSDictionary *views = NSDictionaryOfVariableBindings(tableView);
    [self.view addConstraints:@"H:|[tableView]|" views:views];
    [self.view addConstraints:@"V:|[tableView]|" views:views];

    // Fix the insets fuckup on iPad
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
        CGFloat navigationBarHeight = self.navigationController.navigationBar.frame.size.height;
        tableView.contentInset = UIEdgeInsetsMake(statusBarHeight + navigationBarHeight, 0.0f, 0.0f, 0.0f);
    }

    self.tableView = tableView;
}

- (void)configureRefreshControl
{
    CGRect refreshControlBackgroundViewFrame = self.tableView.bounds;
    refreshControlBackgroundViewFrame.origin.y = -refreshControlBackgroundViewFrame.size.height;
    self.refreshControlBackgroundView = [[UIView alloc] initWithFrame:refreshControlBackgroundViewFrame];
    self.refreshControlBackgroundView.backgroundColor = [UIColor groupTableViewBackgroundColor];

    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];

    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;
    tableViewController.refreshControl = self.refreshControl;
    [tableViewController.tableView addSubview:self.refreshControlBackgroundView];
    self.refreshControl.layer.zPosition = self.refreshControlBackgroundView.layer.zPosition + 1;
}

#pragma mark - Data methods

- (void)loadThread:(MCLThread *)inThread fromBoard:(MCLBoard *)inBoard
{
    self.thread = inThread;
    self.board = inBoard;

    [self updateTitle:inThread.subject];

    // Close thread list in portrait mode
    if (self.masterPopoverController) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }

    // Add loading view
    [self.view addSubview:[[MCLLoadingView alloc] initWithFrame:self.view.frame]];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (selectedIndexPath) {
        [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:NO];
        [self tableView:self.tableView didDeselectRowAtIndexPath:selectedIndexPath];
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *mServiceError;
        NSDictionary *data = [[MCLMServiceConnector sharedConnector] threadWithId:self.thread.threadId
                                                                      fromBoardId:self.board.boardId
                                                                            error:&mServiceError];
        // Process data on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [self fetchedData:data error:mServiceError];

            // Restore tables separatorColor
            [self.tableView setSeparatorColor:self.tableSeparatorColor];
        });
    });
}

- (void)reloadData
{
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (selectedIndexPath) {
        MCLMessageListWidmannStyleTableViewCell *cell =
            (MCLMessageListWidmannStyleTableViewCell *)[self.tableView cellForRowAtIndexPath:selectedIndexPath];

        if (cell.speechSynthesizer.speaking) {
            [cell.speechSynthesizer stopSpeakingAtBoundary:AVSpeechBoundaryWord];
            cell.messageSpeakButton.image = [UIImage imageNamed:@"speakButton.png"];
        }
    }

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *mServiceError;
        NSDictionary *data = [[MCLMServiceConnector sharedConnector] threadWithId:self.thread.threadId
                                                                      fromBoardId:self.board.boardId
                                                                            error:&mServiceError];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self fetchedData:data error:mServiceError];
            [self.refreshControl endRefreshing];
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
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        [dateFormatter setLocale:enUSPOSIXLocale];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];

        self.messages = [NSMutableArray array];
        for (id object in data) {
            NSNumber *messageId = [object objectForKey:@"messageId"];
            NSNumber *level = [object objectForKey:@"level"];
            BOOL mod = [[object objectForKey:@"mod"] boolValue];
            NSString *username = [object objectForKey:@"username"];
            NSString *subject = [object objectForKey:@"subject"];
            NSDate *date = [dateFormatter dateFromString:[object objectForKey:@"date"]];

            MCLMessage *message = [MCLMessage messageWithId:messageId
                                                      level:level
                                                        mod:mod
                                                   username:username
                                                    subject:subject
                                                       date:date];
            [self.messages addObject:message];
        }

        [self.tableView reloadData];

        NSNumber *lastMessageId = self.thread.lastMessageId;

        // If new thread select first message
        BOOL threadIsNew = ![self.readList messageIdIsRead:self.thread.messageId fromThread:self.thread];
        BOOL jumpToLatestPost = [[NSUserDefaults standardUserDefaults] boolForKey:@"jumpToLatestPost"];
        if (threadIsNew) {
            NSIndexPath *firstMessageIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            [self.tableView selectRowAtIndexPath:firstMessageIndexPath
                                        animated:YES
                                  scrollPosition:UITableViewScrollPositionTop];
            [self tableView:self.tableView didSelectRowAtIndexPath:firstMessageIndexPath];
        }
        else if (jumpToLatestPost && lastMessageId > 0) {
            BOOL lastMessageIsNotRead = ![self.readList messageIdIsRead:lastMessageId fromThread:self.thread];
            if (lastMessageIsNotRead) {
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
        }
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
    static NSString *cellIdentifier = @"MessageCell";
    MCLMessage *message = self.messages[i];

    MCLMessageListWidmannStyleTableViewCell *cell =
        (MCLMessageListWidmannStyleTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[MCLMessageListWidmannStyleTableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle
                                                             reuseIdentifier:cellIdentifier];
        cell.translatesAutoresizingMaskIntoConstraints = NO;
    }

    cell.delegate = self;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.separatorInset = UIEdgeInsetsZero;

    [self indentView:cell.messageIndentionConstraint withLevel:message.level];

    if (i > 0 && i == [tableView indexPathForSelectedRow].row) {
        cell.backgroundColor = [UIColor groupTableViewBackgroundColor];

        [cell.messageTextWebView setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
        [cell.messageTextWebView.scrollView setBackgroundColor:[UIColor groupTableViewBackgroundColor]];

        [cell.messageToolbar setHidden:NO];
        [cell.messageTextWebView loadHTMLString:[self messageHtml:message] baseURL:nil];
        [self hideToolbarButtonsForMessage:message inCell:cell atIndexPath:indexPath];
    } else {
        cell.backgroundColor = [UIColor whiteColor];
        [cell.messageToolbar setHidden:YES];
        cell.messageTextWebViewHeightConstraint.constant = 0;
    }

    cell.messageToolbar.translucent = NO;
    cell.messageToolbar.barTintColor = [UIColor groupTableViewBackgroundColor];

    [cell setBoardId:self.board.boardId];
    [cell setMessageId:message.messageId];

    [cell setClipsToBounds:YES];

    cell.messageIndentionImageView.hidden = (i == 0);
    
    cell.messageSubjectLabel.text = message.subject;
    cell.messageUsernameLabel.text = message.username;
    
    if ([message.username isEqualToString:self.username]) {
        cell.messageUsernameLabel.textColor = [UIColor blueColor];
    } else if (message.isMod) {
        cell.messageUsernameLabel.textColor = [UIColor redColor];
    } else {
        cell.messageUsernameLabel.textColor = [UIColor blackColor];
    }
    
    cell.messageDateLabel.text = [NSString stringWithFormat:@" - %@", [self.dateFormatter stringFromDate:message.date]];
    
    [cell.messageUsernameLabel sizeToFit];
    [cell.messageDateLabel sizeToFit];

    [cell.messageTextWebView setNavigationDelegate:self];

    if (i == 0 || [self.readList messageIdIsRead:message.messageId fromThread:self.thread]) {
        [cell markRead];
    } else {
        [cell markUnread];
    }

    return cell;
}

- (void)indentView:(NSLayoutConstraint *)indentionConstraint withLevel:(NSNumber *)level
{
    int indention = 15;
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

- (void)hideToolbarButtonsForMessage:(MCLMessage *)message inCell:(MCLMessageListWidmannStyleTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    BOOL hideNotificationButton = !self.validLogin || ![message.username isEqualToString:self.username];
    [self barButton:cell.messageNotificationButton hide:hideNotificationButton];
    if (!hideNotificationButton) {
        [cell enableNotificationButton:message.notification];
    }

    MCLMessage *nextMessage = nil;
    if (indexPath.row < ([self.messages count] - 1)) {
        nextMessage = self.messages[indexPath.row + 1];
    }

    BOOL hideEditButton =
        !self.validLogin || self.thread.isClosed ||
        !([message.username isEqualToString:self.username] && nextMessage.level <= message.level);
    [self barButton:cell.messageEditButton hide:hideEditButton];

    BOOL hideReplyButton = !self.validLogin || self.thread.isClosed;
    [self barButton:cell.messageReplyButton hide:hideReplyButton];
}


#pragma mark - UITableViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    for (MCLMessageListWidmannStyleTableViewCell *cell in self.tableView.visibleCells) {
        [cell.messageTextWebView setNeedsLayout];
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
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

    return [MCLMessageListViewController messageHtmlSkeletonForHtml:messageHtml withTopMargin:0];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MCLMessageListWidmannStyleTableViewCell *cell =
        (MCLMessageListWidmannStyleTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    BOOL isSelected = [cell isSelected];

    if (isSelected) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [tableView.delegate tableView:tableView didDeselectRowAtIndexPath:indexPath];
    }

    return isSelected ? nil : indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    MCLMessageListWidmannStyleTableViewCell *cell =
        (MCLMessageListWidmannStyleTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    [cell setBackgroundColor:[UIColor groupTableViewBackgroundColor]];

    MCLMessage *message = self.messages[indexPath.row];
    if (message.text) {
        [self putMessage:message toCell:cell atIndexPath:indexPath];
    } else {
        NSDictionary *loginData = nil;
        if ([message.username isEqualToString:self.username]) {
            loginData = @{@"username":self.username,
                          @"password":self.password};
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError *mServiceError;
            NSDictionary *data = [[MCLMServiceConnector sharedConnector] messageWithId:message.messageId
                                                                           fromBoardId:self.board.boardId
                                                                                 login:loginData
                                                                                 error:&mServiceError];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (mServiceError) {
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

                    [tableView deselectRowAtIndexPath:indexPath animated:NO];
                    [tableView.delegate tableView:tableView didDeselectRowAtIndexPath:indexPath];

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

                    cell.messageText = message.text;
                    [cell markRead];
                    [self.readList addMessageId:message.messageId fromThread:self.thread];
                    [self.delegate messageListViewController:self
                                      didReadMessageOnThread:self.thread
                                                  onReadList:self.readList];
                    [self putMessage:message toCell:cell atIndexPath:indexPath];
                }
            });
        });
    }
}

- (void)putMessage:(MCLMessage *)message toCell:(MCLMessageListWidmannStyleTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    [cell.messageTextWebView setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
    [cell.messageTextWebView.scrollView setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
    [cell.messageTextWebView loadHTMLString:[self messageHtml:message] baseURL:nil];
    [self hideToolbarButtonsForMessage:message inCell:cell atIndexPath:indexPath];

    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:NO];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MCLMessageListWidmannStyleTableViewCell *cell =
        (MCLMessageListWidmannStyleTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    
    [cell setBackgroundColor:[UIColor clearColor]];
    [cell.messageTextWebView setBackgroundColor:[UIColor clearColor]];
    [cell.messageTextWebView.scrollView setBackgroundColor:[UIColor clearColor]];
    cell.messageTextWebViewHeightConstraint.constant = 0.0;

    [cell.messageToolbar setHidden:YES];

    if (cell.speechSynthesizer.speaking) {
        [cell.speechSynthesizer stopSpeakingAtBoundary:AVSpeechBoundaryWord];
        cell.messageSpeakButton.image = [UIImage imageNamed:@"speakButton.png"];
    }

    self.selectedCellIndexPath = nil;
    [self updateTableView];
}

- (void)updateTableView
{
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    NSString *heightCode = @"Math.max(document.body.scrollHeight,"
                            " document.body.offsetHeight,"
                            " document.documentElement.clientHeight,"
                            " document.documentElement.scrollHeight,"
                            " document.documentElement.offsetHeight);";
    [webView evaluateJavaScript:heightCode completionHandler:^(NSString *result, NSError *error) {
        NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
        MCLMessageListWidmannStyleTableViewCell *cell =
            (MCLMessageListWidmannStyleTableViewCell *)[self.tableView cellForRowAtIndexPath:selectedIndexPath];
        [cell.messageToolbar setHidden:NO];

        CGFloat contentHeight = [result doubleValue];
        cell.messageTextWebViewHeightConstraint.constant = contentHeight + 44;

        [self updateTableView];

        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        [UIApplication.sharedApplication openURL:navigationAction.request.URL];
        decisionHandler(WKNavigationActionPolicyCancel);
    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

#pragma mark - MCLMessageListWidmannStyleTableViewCellDelegate

- (void)openProfileButtonPressed
{
    [self performSegueWithIdentifier:@"ModalToShowProfile" sender:nil];
}

- (void)editButtonPressed
{
    [self performSegueWithIdentifier:@"ModalToEditReply" sender:nil];
}

- (void)replyButtonPressed
{
    [self performSegueWithIdentifier:@"ModalToComposeReply" sender:nil];
}

#pragma mark - MCLComposeMessageViewControllerDelegate

- (void)messageSentWithType:(NSUInteger)type
{
    [self reloadData];
}

- (void)handleRotationChangeInBackground
{
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone &&
        self.orientationBeforeWentToBackground != interfaceOrientation
    ) {
        [self willTransitionToTraitCollection:self.traitCollection
                    withTransitionCoordinator:self.transitionCoordinator];
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

/*
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
 
    // Code here will execute before the rotation begins.
    // Equivalent to placing it in the deprecated method -[willRotateToInterfaceOrientation:duration:]
    NSLog(@"111111111111111111111111111111111111111111111111111111111111");

    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (!selectedIndexPath) { return; }

    MCLMessageListWidmannStyleTableViewCell *cell =
    (MCLMessageListWidmannStyleTableViewCell*)[self.tableView cellForRowAtIndexPath:selectedIndexPath];
    MCLMessage *message = self.messages[selectedIndexPath.row];

    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // Place code here to perform animations during the rotation.
        // You can pass nil or leave this block empty if not necessary.
        NSLog(@"222222222222222222222222222222222222222222222222222222222222");

        [cell.messageTextWebView setNeedsLayout];
        [cell.messageTextWebView loadHTMLString:[self messageHtml:message] baseURL:nil];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // Code here will execute after the rotation has finished.
        // Equivalent to placing it in the deprecated method -[didRotateFromInterfaceOrientation:]
        NSLog(@"333333333333333333333333333333333333333333333333333333333333");

    }];
}
*/
@end

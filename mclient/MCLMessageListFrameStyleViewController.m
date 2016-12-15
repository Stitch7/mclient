//
//  MCLMessageList2FrameStyleViewController.m
//  mclient
//
//  Created by Christopher Reitz on 16.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLMessageListFrameStyleViewController.h"

#import "constants.h"
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
#import "MCLMessageTableViewCell.h"
#import "MCLBoard.h"
#import "MCLThread.h"
#import "MCLMessage.h"
#import "MCLReadList.h"

#pragma mark - Private Stuff

@interface MCLMessageListFrameStyleViewController ()

@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (strong, nonatomic) AVSpeechSynthesizer *speechSynthesizer;
@property (strong) NSMutableArray *messages;
@property (strong) NSMutableArray *cells;
@property (strong) MCLReadList *readList;
@property (strong) NSString *username;
@property (strong) NSString *password;
@property (assign) BOOL validLogin;
@property (strong) NSDateFormatter *dateFormatter;
@property (strong) UIRefreshControl *refreshControl;
@property (weak, nonatomic) IBOutlet UIView *messageView;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolbarButtonSpeak;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolbarButtonNotification;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolbarButtonEdit;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolbarButtonReply;
@property (assign, nonatomic) UIInterfaceOrientation orientationBeforeWentToBackground;

@end

@implementation MCLMessageListFrameStyleViewController


#pragma mark - ViewController

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.cells = [NSMutableArray array];
    self.readList = [[MCLReadList alloc] init];

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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone &&
        UIInterfaceOrientationIsLandscape(interfaceOrientation)
    ) {
        [self transformMessageViewSizeForInterfaceOrientation:interfaceOrientation];
    }

    // tableView setup
    // Enable statusbar tap to scroll to top
    self.tableView.scrollsToTop = YES;
    // Add refresh control
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
//    [self.tableView addSubview:self.refreshControl];

    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;
    tableViewController.refreshControl = self.refreshControl;


    // webView setup
    self.webView.delegate = self;
    self.webView.scrollView.scrollsToTop = NO;

    // Init toolbar slide gestures
    UISwipeGestureRecognizer *toolbarDownSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(slideMessageViewDownAction)];
    toolbarDownSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
    toolbarDownSwipeRecognizer.cancelsTouchesInView = YES;

    UISwipeGestureRecognizer *toolbarUpSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(slideMessageViewUpAction)];
    toolbarUpSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionUp;
    toolbarUpSwipeRecognizer.cancelsTouchesInView = YES;

    [self.toolbar addGestureRecognizer:toolbarDownSwipeRecognizer];
    [self.toolbar addGestureRecognizer:toolbarUpSwipeRecognizer];

    if (self.board && self.thread) {
        // Set title to threads subject
        self.title = self.thread.subject;

        // Add loading view
        CGRect fullScreenFrame = [(MCLAppDelegate *)[[UIApplication sharedApplication] delegate] fullScreenFrameFromViewController:self];
        [self.view addSubview:[[MCLLoadingView alloc] initWithFrame:fullScreenFrame]];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

        // Load data async
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError *mServiceError;
            NSDictionary *data = [[MCLMServiceConnector sharedConnector] threadWithId:self.thread.threadId fromBoardId:self.board.boardId error:&mServiceError];
            // Process data on main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                [self fetchedData:data error:mServiceError];

                if ( ! mServiceError) {
                    // Select first message
                    NSIndexPath *indexPathOfFirstMessage = [NSIndexPath indexPathForRow:0 inSection:0];
                    [self.tableView selectRowAtIndexPath:indexPathOfFirstMessage animated:NO scrollPosition:UITableViewScrollPositionNone];
                    [self tableView:self.tableView didSelectRowAtIndexPath:indexPathOfFirstMessage];
                }
            });
        });
    } else {
        [self.view addSubview:[[MCLDetailView alloc] initWithFrame:self.view.bounds]];
    }
}

//- (void)viewDidLayoutSubviews
//{
//    [self.refreshControl.superview sendSubviewToBack:self.refreshControl];
//}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (self.speechSynthesizer.speaking) {
        [self.speechSynthesizer stopSpeakingAtBoundary:AVSpeechBoundaryWord];
        self.toolbarButtonSpeak.image = [UIImage imageNamed:@"speakButton.png"];
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self transformMessageViewSizeForInterfaceOrientation:toInterfaceOrientation];

    // Fix zooming webView content on rotate
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (selectedIndexPath) {
        [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:NO];
        [self.tableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        [self.tableView.delegate tableView:self.tableView didSelectRowAtIndexPath:selectedIndexPath];
    }
}

- (void)transformMessageViewSizeForInterfaceOrientation:(UIInterfaceOrientation)forInterfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        CGRect messageViewFrame = self.messageView.frame;
        CGFloat newMessageViewY;
        CGFloat newMessageViewHeight;

        if (UIInterfaceOrientationIsLandscape(forInterfaceOrientation)) {
            CGFloat iOS7Offset = 0.0f;

            CGSize viewSize = self.view.bounds.size;
            if ((NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1)) {
                iOS7Offset = 28.0f;

                // If we started in landscape mode we must switch height and width in iOS7...
                if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                    viewSize = CGSizeMake(viewSize.height, viewSize.width);
                }
            }

            // Check current orientation because willRotateToInterfaceOrientation
            if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
                newMessageViewHeight = viewSize.height;
            } else {
                newMessageViewHeight = viewSize.width;
            }

            if ([UIScreen mainScreen].bounds.size.height == 736) { // 6 Plus :-(
                newMessageViewY = 44.0f + iOS7Offset;
            } else {
                newMessageViewY = 32.0f + iOS7Offset;
            }

            newMessageViewHeight -= newMessageViewY - 2;
        } else {
            newMessageViewY = 65.0f;
            newMessageViewHeight = 300.0f;
        }

        messageViewFrame.origin.y = newMessageViewY;
        messageViewFrame.size.height = newMessageViewHeight;
        self.messageView.frame = messageViewFrame;

        [self adjustWebViewHeightToMessageView];
    } else { // iPad
        if (self.messageView.tag > 0) {
            CGFloat newMessageViewHeight;
            if (UIInterfaceOrientationIsLandscape(forInterfaceOrientation)) {
                newMessageViewHeight = 700;
            } else {
                newMessageViewHeight = 960;
            }

            CGRect messageViewFrame = self.messageView.frame;
            messageViewFrame.size.height = newMessageViewHeight;
            self.messageView.frame = messageViewFrame;

            [self adjustWebViewHeightToMessageView];
        }
    }
}

- (CGFloat)fullViewheight
{
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    if ((NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1) &&
        UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])
    ) {
        statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.width;
    }

    return self.view.bounds.size.height - self.navigationController.navigationBar.bounds.size.height - statusBarHeight;
}

- (void)adjustWebViewHeightToMessageView
{
    CGRect webViewFrame = self.webView.frame;
    webViewFrame.size.height = self.messageView.bounds.size.height - self.toolbar.bounds.size.height;
    self.webView.frame = webViewFrame;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - Data methods

- (void)loadThread:(MCLThread *)inThread fromBoard:(MCLBoard *)inBoard
{
    self.thread = inThread;
    self.board = inBoard;

    // Set title
    self.title = inThread.subject;

    // Close thread list in portrait mode
    if (self.masterPopoverController) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }

    // Visualize loading
    CGRect fullScreenFrame = [(MCLAppDelegate *)[[UIApplication sharedApplication] delegate] fullScreenFrameFromViewController:self];
    [self.view addSubview:[[MCLLoadingView alloc] initWithFrame:fullScreenFrame]];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    // Load data async
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *mServiceError;
        NSDictionary *data = [[MCLMServiceConnector sharedConnector] threadWithId:self.thread.threadId fromBoardId:self.board.boardId error:&mServiceError];
        // Process data on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [self fetchedData:data error:mServiceError];

            // Scrool table to top
            [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];

            if ( ! mServiceError) {
                // Select first message
                NSIndexPath *indexPathOfFirstMessage = [NSIndexPath indexPathForRow:0 inSection:0];
                [self.tableView selectRowAtIndexPath:indexPathOfFirstMessage animated:NO scrollPosition:UITableViewScrollPositionNone];
                [self tableView:self.tableView didSelectRowAtIndexPath:indexPathOfFirstMessage];
            }
        });
    });
}

//- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
//{
//    // Fixes refreshcontrol's too litle space problem
//    if (scrollView.contentOffset.y < (self.tableView.bounds.size.height / -5) && ! [self.refreshControl isRefreshing]) {
//        [self.refreshControl beginRefreshing];
//        [self reloadData];
//    }
//}

- (void)reloadData
{
//    if ( ! [self.refreshControl isRefreshing]) {

//        NSLog(@"reload");

        NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];

        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError *mServiceError;
            NSDictionary *data = [[MCLMServiceConnector sharedConnector] threadWithId:self.thread.threadId fromBoardId:self.board.boardId error:&mServiceError];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self fetchedData:data error:mServiceError];
                [self.refreshControl endRefreshing];

                [self.tableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                [self tableView:self.tableView didSelectRowAtIndexPath:selectedIndexPath];
            });
        });
//    }
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
        CGRect fullScreenFrame = [(MCLAppDelegate *)[[UIApplication sharedApplication] delegate] fullScreenFrameFromViewController:self];
        switch (error.code) {
            case -2:
                [self.view addSubview:[[MCLInternetConnectionErrorView alloc] initWithFrame:fullScreenFrame hideSubLabel:YES]];
                break;

            default:
                [self.view addSubview:[[MCLMServiceErrorView alloc] initWithFrame:fullScreenFrame andText:[error localizedDescription] hideSubLabel:YES]];
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
    }
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

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
    MCLMessageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];

    [self.cells setObject:cell atIndexedSubscript:i];

    [cell setBoardId:self.board.boardId];
    [cell setMessageId:message.messageId];

    [self indentView:(UIView *)cell.readSymbolView withLevel:message.level startingAtX:5];
    [self indentView:(UIView *)cell.messageIndentionImageView withLevel:message.level startingAtX:20];
    [self indentView:cell.messageSubjectLabel withLevel:message.level startingAtX:30];
    [self indentView:cell.messageUsernameLabel withLevel:message.level startingAtX:30];

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

    // Place dateLabel after authorLabel
    CGRect dateLabelFrame = cell.messageDateLabel.frame;
    dateLabelFrame.origin = CGPointMake(cell.messageUsernameLabel.frame.origin.x + cell.messageUsernameLabel.frame.size.width, dateLabelFrame.origin.y);
    cell.messageDateLabel.frame = dateLabelFrame;

    if (i == 0 || [self.readList messageIdIsRead:message.messageId]) {
        [cell markRead];
    } else {
        [cell markUnread];
    }

    return cell;
}

- (void)indentView:(UIView *)view withLevel:(NSNumber *)level startingAtX:(CGFloat)x
{
    int indention = 10;

    CGRect frame = view.frame;
    frame.origin = CGPointMake(x + (indention * [level integerValue]), frame.origin.y);
    view.frame = frame;
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
            messageHtml = [wifiReach currentReachabilityStatus] == ReachableViaWiFi ? message.textHtmlWithImages : message.textHtml;
            break;
        }
        case kMCLSettingsShowImagesNever:
            messageHtml = message.textHtml;
            break;
    }

    return [MCLMessageListViewController messageHtmlSkeletonForHtml:messageHtml withTopMargin:10];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger i = indexPath.row;

    MCLMessageTableViewCell *cell = (MCLMessageTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];

    MCLMessage *message = self.messages[i];

    MCLMessage *nextMessage = nil;
    if (indexPath.row < ([self.messages count] - 1)) {
        nextMessage = self.messages[i + 1];
    }

    self.toolbarButtonNotification.image = [UIImage imageNamed:@"notificationButtonDisabled.png"];
    BOOL hideNotificationButton = ! self.validLogin || ! [message.username isEqualToString:self.username];
    [self barButton:self.toolbarButtonNotification hide:hideNotificationButton];

    BOOL hideEditButton = ! self.validLogin || self.thread.isClosed || ! ([message.username isEqualToString:self.username] && nextMessage.level <= message.level);
    [self barButton:self.toolbarButtonEdit hide:hideEditButton];

    BOOL hideReplyButton = ! self.validLogin || self.thread.isClosed;
    [self barButton:self.toolbarButtonReply hide:hideReplyButton];

    if (message.text) {
        [self loadMessage:message fromCell:cell];
    } else {
        NSDictionary *loginData = nil;
        if ([message.username isEqualToString:self.username]) {
            loginData = @{@"username":self.username,
                          @"password":self.password};
        }

        [self.webView loadHTMLString:@"" baseURL:nil];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        CGRect mvBounds = self.messageView.bounds;
        CGRect loadingFrame = CGRectMake(mvBounds .origin.x, mvBounds.origin.y, mvBounds.size.width, mvBounds.size.height - self.toolbar.frame.size.height - 1);
        [self.messageView addSubview:[[MCLLoadingView alloc] initWithFrame:loadingFrame]];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError *mServiceError;
            NSDictionary *data = [[MCLMServiceConnector sharedConnector] messageWithId:message.messageId fromBoardId:self.board.boardId login:loginData error:&mServiceError];
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                for (id subview in self.messageView.subviews) {
                    if ([[subview class] isSubclassOfClass: [MCLLoadingView class]]) {
                        [subview removeFromSuperview];
                    }
                }

                if (mServiceError) {
                    // [tableView deselectRowAtIndexPath:indexPath animated:NO];
                    // [tableView.delegate tableView:tableView didDeselectRowAtIndexPath:indexPath];

                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                                    message:[mServiceError localizedDescription]
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                          otherButtonTitles:nil];
                    [alert show];
                } else {
                    message.userId = [data objectForKey:@"userId"];
                    message.text = [data objectForKey:@"text"];
                    message.textHtml = [data objectForKey:@"textHtml"];
                    message.textHtmlWithImages = [data objectForKey:@"textHtmlWithImages"];
                    if ([data objectForKey:@"notification"] != [NSNull null]) {
                        message.notification = [[data objectForKey:@"notification"] boolValue];
                    }

                    [cell markRead];
                    [self.readList addMessageId:message.messageId];

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

- (void)loadMessage:(MCLMessage *)message fromCell:(MCLMessageTableViewCell *)cell
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

#pragma mark - UIWebView delegate

-(BOOL)webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType
{
    BOOL shouldStartLoad = YES;

    // Open links in Safari
    if (inType == UIWebViewNavigationTypeLinkClicked) {
        [[UIApplication sharedApplication] openURL:[inRequest URL]];
        shouldStartLoad = NO;
    }

    return shouldStartLoad;
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
        NSDictionary *data = [[MCLMServiceConnector sharedConnector] threadWithId:self.thread.threadId fromBoardId:self.board.boardId error:&mServiceError];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self fetchedData:data error:mServiceError];

            if (type == kMCLComposeTypeEdit) {
                // Reload selected message
                [self.tableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                [self tableView:self.tableView didSelectRowAtIndexPath:selectedIndexPath];
            }
        });
    });

}

- (void)handleRotationChangeInBackground
{
    if (self.orientationBeforeWentToBackground != [[UIApplication sharedApplication] statusBarOrientation]) {
//        [self willRotateToInterfaceOrientation:interfaceOrientation duration:0];
        [self willTransitionToTraitCollection:self.traitCollection withTransitionCoordinator:self.transitionCoordinator];
    }
}


#pragma mark - Actions

- (void)backAction
{
    [self performSegueWithIdentifier:@"PushBackToThreadList" sender:nil];
}

- (void)slideMessageViewDownAction
{
    // Cache initial height
    [self.messageView setTag:self.messageView.bounds.size.height];

    self.messageView.layer.needsDisplayOnBoundsChange = YES;
    self.messageView.contentMode = UIViewContentModeRedraw;

    [UIView animateWithDuration:.4f animations:^{
        CGRect bounds = self.messageView.bounds;
        CGPoint center = self.messageView.center;
        bounds.size.height += [self fullViewheight] - self.messageView.bounds.size.height;
        center.y += ([self fullViewheight] - self.messageView.bounds.size.height) / 2;
        self.messageView.bounds = bounds;
        self.messageView.center = center;
    }];

    self.messageView.layer.needsDisplayOnBoundsChange = NO;

    [self adjustWebViewHeightToMessageView];
}

- (void)slideMessageViewUpAction
{
    if (self.messageView.tag > 0) {
        self.messageView.layer.needsDisplayOnBoundsChange = YES;
        self.messageView.contentMode = UIViewContentModeRedraw;

        [UIView animateWithDuration:.4f animations:^{
            CGRect bounds = self.messageView.bounds;
            CGPoint center = self.messageView.center;
            bounds.size.height -= [self fullViewheight] - self.messageView.tag;
            center.y -= ([self fullViewheight] - self.messageView.tag) / 2;
            self.messageView.bounds = bounds;
            self.messageView.center = center;
        }];

        self.messageView.layer.needsDisplayOnBoundsChange = NO;

        self.messageView.tag = 0;

        [self adjustWebViewHeightToMessageView];
    }
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
        MCLMessageTableViewCell *selectedCell = (MCLMessageTableViewCell*)[self.tableView cellForRowAtIndexPath:selectedIndexPath];

        // Backup of UIWebView content because it's get manipulated by our operation below
        NSString *webviewTextBackup = [self.webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByTagName(\"html\")[0].innerHTML;"];

        // Remove quoted text (font tags)
        [self.webView stringByEvaluatingJavaScriptFromString:@"var fontTags = document.getElementsByTagName(\"font\"); for (var i=0; i < fontTags.length; x++) { fontTags[i].remove() };"];
        NSString *text = [self.webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByTagName(\"body\")[0].textContent;"];
        text = [[selectedCell.messageSubjectLabel.text  stringByAppendingString:@"..."] stringByAppendingString:text];
        text = [[NSString stringWithFormat:@"Von %@...", selectedCell.messageUsernameLabel.text] stringByAppendingString:text];

        // Restoring backuped original content
        [self.webView loadHTMLString:webviewTextBackup baseURL:nil];

        // Speak text
        AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:text];
        [utterance setVoice:[AVSpeechSynthesisVoice voiceWithLanguage:@"de-DE"]];

        float rate = AVSpeechUtteranceDefaultSpeechRate;
        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1) {
            rate = rate / 2;
        }
        [utterance setRate:rate];

        [self.speechSynthesizer speakUtterance:utterance];
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
        [[MCLMServiceConnector sharedConnector] notificationForMessageId:message.messageId boardId:self.board.boardId username:username password:password error:&mServiceError];
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


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    self.orientationBeforeWentToBackground = [[UIApplication sharedApplication] statusBarOrientation];

    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    MCLMessage *message = self.messages[indexPath.row];

    if ([segue.identifier isEqualToString:@"ModalToComposeReply"]) {
        MCLComposeMessageViewController *destinationViewController = ((MCLComposeMessageViewController *)[[segue.destinationViewController viewControllers] objectAtIndex:0]);
        NSString *subject = message.subject;

        NSString *subjectReplyPrefix = @"Re:";
        if ([subject length] < 3 || ! [[subject substringToIndex:3] isEqualToString:subjectReplyPrefix]) {
            subject = [subjectReplyPrefix stringByAppendingString:subject];
        }

        [destinationViewController setDelegate:self];
        [destinationViewController setType:kMCLComposeTypeReply];
        [destinationViewController setBoardId:self.board.boardId];
        [destinationViewController setMessageId:message.messageId];
        [destinationViewController setSubject:subject];
    } else if ([segue.identifier isEqualToString:@"ModalToEditReply"]) {
        MCLComposeMessageViewController *destinationViewController = ((MCLComposeMessageViewController *)[[segue.destinationViewController viewControllers] objectAtIndex:0]);
        [destinationViewController setDelegate:self];
        [destinationViewController setType:kMCLComposeTypeEdit];
        [destinationViewController setBoardId:self.board.boardId];
        [destinationViewController setMessageId:message.messageId];
        [destinationViewController setSubject:message.subject];
        [destinationViewController setText:message.text];
    } else if ([segue.identifier isEqualToString:@"ModalToShowProfile"]) {
        MCLProfileTableViewController *destinationViewController = ((MCLProfileTableViewController *)[[segue.destinationViewController viewControllers] objectAtIndex:0]);
        [destinationViewController setDelegate:self];
        [destinationViewController setUserId:message.userId];
        [destinationViewController setUsername:message.username];
    }
}

@end

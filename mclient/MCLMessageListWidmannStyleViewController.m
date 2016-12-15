//
//  MCLMessageListTableViewController.m
//  mclient
//
//  Created by Christopher Reitz on 25.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "constants.h"
#import "KeychainItemWrapper.h"
#import "Reachability.h"
#import "MCLAppDelegate.h"
#import "MCLMServiceConnector.h"
#import "MCLMessageListWidmannStyleViewController.h"
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


@interface MCLMessageListWidmannStyleViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSIndexPath *selectedCellIndexPath;
@property (assign, nonatomic) CGFloat selectedCellHeight;
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) UIView *refreshControlBackgroundView;
@property (strong, nonatomic) UIColor *tableSeparatorColor;
@property (strong, nonatomic) NSMutableArray *messages;
@property (strong, nonatomic) NSMutableDictionary *cells;
@property (strong, nonatomic) MCLReadList *readList;
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *password;
@property (assign, nonatomic) BOOL validLogin;
@property (strong, nonatomic) UIColor *veryLightGreyColor;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (assign, nonatomic) UIInterfaceOrientation orientationBeforeWentToBackground;

@end

@implementation MCLMessageListWidmannStyleViewController

#pragma mark - ViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.cells = [NSMutableDictionary dictionary];
    self.readList = [[MCLReadList alloc] init];

    self.veryLightGreyColor = [UIColor colorWithRed:240/255.0f green:240/255.0f blue:240/255.0f alpha:1.0f];

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

    // tableView setup
    // Cache original tables separatorColor and set to clear to avoid flickering loading view
    self.tableSeparatorColor = [self.tableView separatorColor];
    [self.tableView setSeparatorColor:[UIColor clearColor]];
    // Enable statusbar tap to scroll to top for tableView
    self.tableView.scrollsToTop = YES;
    // Add refresh control
    CGRect refreshControlBackgroundViewFrame = self.tableView.bounds;
    refreshControlBackgroundViewFrame.origin.y = -refreshControlBackgroundViewFrame.size.height;
    self.refreshControlBackgroundView = [[UIView alloc] initWithFrame:refreshControlBackgroundViewFrame];
    self.refreshControlBackgroundView.backgroundColor = [UIColor groupTableViewBackgroundColor];
//    [self.tableView addSubview:self.refreshControlBackgroundView];

    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
//    [self.tableView addSubview:self.refreshControl];

    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;
    tableViewController.refreshControl = self.refreshControl;
    [tableViewController.tableView addSubview:self.refreshControlBackgroundView];
    self.refreshControl.layer.zPosition = self.refreshControlBackgroundView.layer.zPosition + 1;

    if (self.board && self.thread) {
        // Set title to threads subject
        self.title = self.thread.subject;

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
        MCLMessageTableViewCell *cell = (MCLMessageTableViewCell*)[self.tableView cellForRowAtIndexPath:selectedIndexPath];
        if (cell.speechSynthesizer.speaking) {
            [cell.speechSynthesizer stopSpeakingAtBoundary:AVSpeechBoundaryWord];
            cell.messageSpeakButton.image = [UIImage imageNamed:@"speakButton.png"];
        }
    }
}

//-(void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
//{
//    // Fix zooming webView content on rotate
//    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
//    if (selectedIndexPath) {
//        [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:NO];
//        [self.tableView.delegate tableView:self.tableView didDeselectRowAtIndexPath:selectedIndexPath];
//        [self.tableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
//        [self.tableView.delegate tableView:self.tableView didSelectRowAtIndexPath:selectedIndexPath];
//    }
//}

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

    // Add loading view
    CGRect fullScreenFrame = [(MCLAppDelegate *)[[UIApplication sharedApplication] delegate] fullScreenFrameFromViewController:self];
    [self.view addSubview:[[MCLLoadingView alloc] initWithFrame:fullScreenFrame]];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (selectedIndexPath) {
        [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:NO];
        [self tableView:self.tableView didDeselectRowAtIndexPath:selectedIndexPath];
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *mServiceError;
        NSDictionary *data = [[MCLMServiceConnector sharedConnector] threadWithId:self.thread.threadId fromBoardId:self.board.boardId error:&mServiceError];
        // Process data on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [self fetchedData:data error:mServiceError];

            // Restore tables separatorColor
            [self.tableView setSeparatorColor:self.tableSeparatorColor];

            // Scrool table to top
            [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
        });
    });
}

- (void)reloadData
{
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (selectedIndexPath) {
        MCLMessageTableViewCell *cell = (MCLMessageTableViewCell*)[self.tableView cellForRowAtIndexPath:selectedIndexPath];

        // On iOS7 deselect the selected cell manually before table is reloaded,
        // this is done automatically on iOS8 after the reload which looks smoother
        if ((NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1)) {
            [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:NO];
            [self tableView:self.tableView didDeselectRowAtIndexPath:selectedIndexPath];
        }

        if (cell.speechSynthesizer.speaking) {
            [cell.speechSynthesizer stopSpeakingAtBoundary:AVSpeechBoundaryWord];
            cell.messageSpeakButton.image = [UIImage imageNamed:@"speakButton.png"];
        }
    }

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *mServiceError;
        NSDictionary *data = [[MCLMServiceConnector sharedConnector] threadWithId:self.thread.threadId fromBoardId:self.board.boardId error:&mServiceError];
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

        // If new thread select first message
        if ( ! [self.readList messageIdIsRead:[[self.messages firstObject] messageId]]) {
            NSIndexPath *firstMessageIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            [self tableView:self.tableView didSelectRowAtIndexPath:firstMessageIndexPath];
            [self.tableView selectRowAtIndexPath:firstMessageIndexPath animated:YES scrollPosition:0];
        }
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

    static NSString *cellIdentifier = @"MessageCell";
    MCLMessageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];

    [self.cells setObject:cell forKey:@(i)];

    if ([cell isSelected]) {
        cell.backgroundColor = self.veryLightGreyColor;
        [cell.messageTextWebView setBackgroundColor:self.veryLightGreyColor];
        [cell.messageToolbar setHidden:NO];
        [cell.messageTextWebView loadHTMLString:[self messageHtml:message] baseURL:nil];
        [self hideToolbarButtonsForMessage:message inCell:cell atIndexPath:indexPath];
    } else {
        cell.backgroundColor = [UIColor whiteColor];
        [cell.messageToolbar setHidden:YES];
    }

    // TableView should scoll to top
    cell.messageTextWebView.scrollView.scrollsToTop = NO;

    cell.messageToolbar.translucent = NO;
    cell.messageToolbar.barTintColor = self.veryLightGreyColor;

    [cell setBoardId:self.board.boardId];
    [cell setMessageId:message.messageId];

    [cell setClipsToBounds:YES];

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
    
    [cell.messageTextWebView setDelegate:self];
    
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

- (void)hideToolbarButtonsForMessage:(MCLMessage *)message inCell:(MCLMessageTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    BOOL hideNotificationButton = ! self.validLogin || ! [message.username isEqualToString:self.username];
    [self barButton:cell.messageNotificationButton hide:hideNotificationButton];
    if ( ! hideNotificationButton) {
        [cell enableNotificationButton:message.notification];
    }

    MCLMessage *nextMessage = nil;
    if (indexPath.row < ([self.messages count] - 1)) {
        nextMessage = self.messages[indexPath.row + 1];
    }

    BOOL hideEditButton = ! self.validLogin || self.thread.isClosed || ! ([message.username isEqualToString:self.username] && nextMessage.level <= message.level);
    [self barButton:cell.messageEditButton hide:hideEditButton];

    BOOL hideReplyButton = ! self.validLogin || self.thread.isClosed;
    [self barButton:cell.messageReplyButton hide:hideReplyButton];
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 60;

    if (indexPath == self.selectedCellIndexPath) {
        height = self.selectedCellHeight;
    } else if ([tableView indexPathsForSelectedRows].count && [[tableView indexPathsForSelectedRows] indexOfObject:indexPath] != NSNotFound) {
        MCLMessageTableViewCell *cell = [self.cells objectForKey:@(indexPath.row)];
        CGFloat webViewHeight = cell.messageTextWebView.scrollView.contentSize.height;
        CGFloat toolbarHeight = cell.messageToolbar.frame.size.height;
        height = height + 10 + webViewHeight + toolbarHeight;

        self.selectedCellIndexPath = indexPath;
        self.selectedCellHeight = height;
	}

    return height;
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
            messageHtml = [wifiReach currentReachabilityStatus] == ReachableViaWiFi ? message.textHtmlWithImages : message.textHtml;
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
    MCLMessageTableViewCell *cell = (MCLMessageTableViewCell*)[tableView cellForRowAtIndexPath:indexPath];
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

    MCLMessageTableViewCell *cell = (MCLMessageTableViewCell*)[tableView cellForRowAtIndexPath:indexPath];
    [cell setBackgroundColor:self.veryLightGreyColor];

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
            NSDictionary *data = [[MCLMServiceConnector sharedConnector] messageWithId:message.messageId fromBoardId:self.board.boardId login:loginData error:&mServiceError];
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
                } else {
                    message.userId = [data objectForKey:@"userId"];
                    message.text = [data objectForKey:@"text"];
                    message.textHtml = [data objectForKey:@"textHtml"];
                    message.textHtmlWithImages = [data objectForKey:@"textHtmlWithImages"];
                    if ([data objectForKey:@"notification"] != [NSNull null]) {
                        message.notification = [[data objectForKey:@"notification"] boolValue];
                    }

                    cell.messageText = message.text;
                    [cell markRead];
                    [self.readList addMessageId:message.messageId];
                    
                    [self putMessage:message toCell:cell atIndexPath:indexPath];
                }
            });
        });
    }
}

- (void)putMessage:(MCLMessage *)message toCell:(MCLMessageTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    [cell.messageTextWebView setBackgroundColor:self.veryLightGreyColor];
    [cell.messageTextWebView loadHTMLString:[self messageHtml:message] baseURL:nil];
    [self hideToolbarButtonsForMessage:message inCell:cell atIndexPath:indexPath];

    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:NO];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MCLMessageTableViewCell *cell = (MCLMessageTableViewCell*)[tableView cellForRowAtIndexPath:indexPath];
    
    [cell setBackgroundColor:[UIColor clearColor]];
    [cell.messageTextWebView setBackgroundColor:[UIColor clearColor]];

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

#pragma mark - UIWebViewDelegate

-(BOOL)webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType {
    BOOL shouldStartLoad = YES;
    
    // Open links in Safari
    if (inType == UIWebViewNavigationTypeLinkClicked) {
        [[UIApplication sharedApplication] openURL:[inRequest URL]];
        shouldStartLoad = NO;
    }
    
    return shouldStartLoad;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    CGRect frame = webView.frame;
    frame.size.height = 5.0f;
    webView.frame = frame;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    // UIWebView object has fully loaded.
    if ([[webView stringByEvaluatingJavaScriptFromString:@"document.readyState"] isEqualToString:@"complete"]) {
        // Resize text view to content height
        CGFloat height = [[webView stringByEvaluatingJavaScriptFromString:@"Math.max(document.body.scrollHeight, "
                                                                           "document.body.offsetHeight, "
                                                                           "document.documentElement.clientHeight, "
                                                                           "document.documentElement.scrollHeight, "
                                                                           "document.documentElement.offsetHeight);"] integerValue];
        CGRect webViewFrame = webView.frame;
        webViewFrame.size.height = height;
        webView.frame = webViewFrame;
        
        // Disable bouncing in webview
        for (id subview in webView.subviews) {
            if ([[subview class] isSubclassOfClass: [UIScrollView class]]) {
                [subview setBounces:NO];
            }
        }

        NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
        MCLMessageTableViewCell *cell = (MCLMessageTableViewCell*)[self.tableView cellForRowAtIndexPath:selectedIndexPath];

        [cell.messageToolbar setHidden:NO];

        // Resize table cell
        [self updateTableView];

        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }
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
        [self willTransitionToTraitCollection:self.traitCollection withTransitionCoordinator:self.transitionCoordinator];
    }
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

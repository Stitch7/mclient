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
#import "MCLMServiceConnector.h"
#import "MCLMessageListWidmannStyleViewController.h"
#import "MCLProfileTableViewController.h"
#import "MCLDetailView.h"
#import "MCLLoadingView.h"
#import "MCLMessageTableViewCell.h"
#import "MCLBoard.h"
#import "MCLThread.h"
#import "MCLMessage.h"
#import "MCLReadList.h"


@interface MCLMessageListWidmannStyleViewController ()

@property (strong, nonatomic) UIPopoverController *masterPopoverController;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong) UIRefreshControl *refreshControl;
@property (strong) UIColor *tableSeparatorColor;
@property (strong) MCLMServiceConnector *mServiceConnector;
@property (strong) NSMutableArray *messages;
@property (strong) NSMutableDictionary *cells;
@property (strong) MCLReadList *readList;
@property (strong) NSString *username;
@property (strong) NSString *password;
@property (assign) BOOL validLogin;
@property (strong) UIColor *veryLightGreyColor;
@property (strong) NSDateFormatter *dateFormatter;

@end

@implementation MCLMessageListWidmannStyleViewController

#pragma mark - ViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.mServiceConnector = [[MCLMServiceConnector alloc] init];
    self.cells = [NSMutableDictionary dictionary];
    self.readList = [[MCLReadList alloc] init];
    
    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:identifier accessGroup:nil];
    self.username = [keychainItem objectForKey:(__bridge id)(kSecAttrAccount)];
    NSData *passwordData = [keychainItem objectForKey:(__bridge id)(kSecValueData)];
    self.password = [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];
    self.validLogin = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([self.username length] > 0 && [self.password length] > 0) {
            NSError *error;
            self.validLogin = ([[[MCLMServiceConnector alloc] init] testLoginWIthUsername:self.username password:self.password error:&error]);
        }
    });

    self.veryLightGreyColor = [UIColor colorWithRed:240/255.0f green:240/255.0f blue:240/255.0f alpha:1.0f];
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDoesRelativeDateFormatting:YES];
    [self.dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [self.dateFormatter setTimeStyle:NSDateFormatterShortStyle];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Cache original tables separatorColor and set to clear to avoid flickering loading view
    self.tableSeparatorColor = [self.tableView separatorColor];
    [self.tableView setSeparatorColor:[UIColor clearColor]];
    // Enable statusbar tap to scroll to top for tableView
    self.tableView.scrollsToTop = YES;

    // Init refresh control
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];

    if (self.board && self.thread) {
        // Set title to threads subject
        self.title = self.thread.subject;

        // Preserve selection between presentations.
        //    self.clearsSelectionOnViewWillAppear = NO; //TODO

        // Visualize loading
        [self.view addSubview:[[MCLLoadingView alloc] initWithFrame:self.view.bounds]];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

        // Load data async
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData *data = [self loadData];
            // Process data on main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                [self fetchedData:data];
                // Remove loading view
                for (id subview in self.view.subviews) {
                    if ([[subview class] isSubclassOfClass: [MCLLoadingView class]]) {
                        [subview removeFromSuperview];
                    }
                }
                // Restore tables separatorColor
                [self.tableView setSeparatorColor:self.tableSeparatorColor];
            });
        });
    } else {
        self.title = @"M!client"; //TODO Read from bundle
        [self.view addSubview:[[MCLDetailView alloc] initWithFrame:self.view.bounds]];
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (selectedIndexPath) {
        [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:NO];
        [self.tableView.delegate tableView:self.tableView didDeselectRowAtIndexPath:selectedIndexPath];
        [self.tableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        [self.tableView.delegate tableView:self.tableView didSelectRowAtIndexPath:selectedIndexPath];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

    // Add loading view
    [self.view addSubview:[[MCLLoadingView alloc] initWithFrame:self.view.bounds]];

    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (selectedIndexPath) {
        [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:YES]; //TODO needed?
        [self tableView:self.tableView didDeselectRowAtIndexPath:selectedIndexPath];
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [self loadData];
        // Process data on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [self fetchedData:data];
            // Remove loading view on main thread
            for (id subview in self.view.subviews) {
                if ([[subview class] isSubclassOfClass: [MCLLoadingView class]] ||
                    [[subview class] isSubclassOfClass: [MCLDetailView class]]
                ) {
                    [subview removeFromSuperview];
                }
            }
            // Restore tables separatorColor
            [self.tableView setSeparatorColor:self.tableSeparatorColor];

            // Scrool table to top
            [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
        });
    });
}

- (NSData *)loadData
{
    NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/messagelist/%@", kMServiceBaseURL, self.board.boardId, self.thread.threadId];
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString: urlString]];

    return data;
}

- (void)reloadData
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [self loadData];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self fetchedData:data];
            [self.refreshControl endRefreshing];
        });
    });
}

- (void)fetchedData:(NSData *)responseData
{
    self.messages = [NSMutableArray array];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    
    NSError* error;
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
    for (id object in json) {
        NSNumber *messageId = [object objectForKey:@"messageId"];
        NSNumber *level = [object objectForKey:@"level"];
        BOOL mod = [[object objectForKey:@"mod"] boolValue];
        NSString *username = [object objectForKey:@"username"];
        NSString *subject = [object objectForKey:@"subject"];
        NSDate *date = [dateFormatter dateFromString:[object objectForKey:@"date"]];
        
        MCLMessage *message = [MCLMessage messageWithId:messageId
                                                  level:level
                                                 userId:nil
                                                    mod:mod
                                               username:username
                                                subject:subject
                                                   date:date
                                                   text:nil
                                               textHtml:nil
                                     textHtmlWithImages:nil];
        [self.messages addObject:message];
    }

    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.tableView reloadData];

    // If new thread select first message
    if ( ! [self.readList messageIdIsRead:[[self.messages firstObject] messageId]]) {
        NSIndexPath *firstMessageIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self tableView:self.tableView didSelectRowAtIndexPath:firstMessageIndexPath];
        [self.tableView selectRowAtIndexPath:firstMessageIndexPath animated:YES scrollPosition:0];
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

    [self.cells setObject:cell forKey:@(i)];

    if ([cell isSelected]) {
        cell.backgroundColor = self.veryLightGreyColor;
        [cell.messageTextWebView setBackgroundColor:self.veryLightGreyColor];
        [cell.messageToolbar setHidden:NO];
        [cell.messageTextWebView loadHTMLString:[self messageHtml:message] baseURL:nil];
    } else {
        cell.backgroundColor = [UIColor clearColor];
        [cell.messageToolbar setHidden:YES];
    }

    // TableView should scoll to top
    cell.messageTextWebView.scrollView.scrollsToTop = NO;

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
    
    BOOL hideNotificationButton = ! self.validLogin ||  ! [message.username isEqualToString:self.username];
    [self barButton:cell.messageNotificationButton hide:hideNotificationButton];
    
    if ( ! hideNotificationButton) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError *mServiceError;
            NSInteger notificationStatus = [self.mServiceConnector notificationStatusForMessageId:message.messageId
                                                                                          boardId:self.board.boardId
                                                                                         username:self.username
                                                                                         password:self.password
                                                                                            error:&mServiceError];
            dispatch_async(dispatch_get_main_queue(), ^{
                [cell enableNotificationButton:notificationStatus];
            });
        });
    }
    
    BOOL hideEditButton = ! self.validLogin || self.thread.isClosed || ! ([message.username isEqualToString:self.username] && nextMessage.level <= message.level);
    [self barButton:cell.messageEditButton hide:hideEditButton];

    BOOL hideReplyButton = ! self.validLogin || self.thread.isClosed;
    [self barButton:cell.messageReplyButton hide:hideReplyButton];

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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 60;

	if ([tableView indexPathsForSelectedRows].count && [[tableView indexPathsForSelectedRows] indexOfObject:indexPath] != NSNotFound) {
        MCLMessageTableViewCell *cell = [self.cells objectForKey:@(indexPath.row)];
        CGFloat webViewHeight = cell.messageTextWebView.scrollView.contentSize.height;
        CGFloat toolbarHeight = cell.messageToolbar.frame.size.height;
        height = height + 10 + webViewHeight + toolbarHeight;
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

    messageHtml = [NSString stringWithFormat:@""
                   "<head>"
                   "<script type=\"text/javascript\">"
                   "    function spoiler(obj) {"
                   "        if (obj.nextSibling.style.display === 'none') {"
                   "            obj.nextSibling.style.display = 'inline';"
                   "        } else {"
                   "            obj.nextSibling.style.display = 'none';"
                   "        }"
                   "    }"
                   "</script>"
                   "<style>"
                   "    * {"
                   "        font-family: \"Helvetica Neue\";"
                   "        font-size: 14px;"
                   "    }"
                   "    body {"
                   "        margin: 0 20px 10px 20px;"
                   "        padding: 0px;"
                   "    }"
                   "    img {"
                   "        max-width: 100%%;"
                   "    }"
                   "    button > img {"
                   "        content:url(\"http://www.maniac-forum.de/forum/images/spoiler.png\");"
                   "        width: 17px;"
                   "    }"
                   "</style>"
                   "</head>"
                   "<body>%@</body>", messageHtml];

    return messageHtml;
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
    MCLMessageTableViewCell *cell = (MCLMessageTableViewCell*)[tableView cellForRowAtIndexPath:indexPath];
    [cell setBackgroundColor:self.veryLightGreyColor];

    MCLMessage *message = self.messages[indexPath.row];
    if (message.text) {
        [self putMessage:message toCell:cell atIndexPath:indexPath];
    } else {
        NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/message/%@", kMServiceBaseURL, self.board.boardId, message.messageId];
        NSURL *url = [NSURL URLWithString:urlString];

        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

            if (connectionError) {
                [tableView deselectRowAtIndexPath:indexPath animated:NO];
                [tableView.delegate tableView:tableView didDeselectRowAtIndexPath:indexPath];

                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error"
                                                                message:[connectionError localizedDescription]
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];

            } else {
                NSError *jsonParseError;
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonParseError];

                message.userId = [json objectForKey:@"userId"];
                message.text = [json objectForKey:@"text"];
                message.textHtml = [json objectForKey:@"textHtml"];
                message.textHtmlWithImages = [json objectForKey:@"textHtmlWithImages"];

                cell.messageText = message.text;
                [cell markRead];
                [self.readList addMessageId:message.messageId];

                [self putMessage:message toCell:cell atIndexPath:indexPath];
            }
        }];
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    }
}

- (void) putMessage:(MCLMessage *)message toCell:(MCLMessageTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    [cell.messageTextWebView setBackgroundColor:self.veryLightGreyColor];
    [cell.messageTextWebView loadHTMLString:[self messageHtml:message] baseURL:nil];

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

        // Show toolbar after short delay to avoid skidding through text
        [cell.messageToolbar performSelector:@selector(setHidden:) withObject:nil afterDelay:0.2];
        // [cell.messageToolbar setHidden:NO];

        // Resize table cell
        [self updateTableView];
    }
}


#pragma mark - UISplitViewControllerDelegate

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = @"Threads";
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}


#pragma mark - MCLComposeMessageViewControllerDelegate

- (void)composeMessageViewControllerDidFinish:(MCLComposeMessageViewController *)inController
{
    [self.tableView reloadData];
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    MCLMessage *message = self.messages[indexPath.row];
    
    if ([segue.identifier isEqualToString:@"ModalToComposeReply"]) {
        MCLComposeMessageViewController *destinationViewController = ((MCLComposeMessageViewController *)[[segue.destinationViewController viewControllers] objectAtIndex:0]);
        NSString *subject = message.subject;
        NSString *subjectReplyPrefix = @"Re:";
        if ([subject length] < 3 || ![[subject substringToIndex:3] isEqualToString:subjectReplyPrefix]) {
            subject = [subjectReplyPrefix stringByAppendingString:subject];
        }
        [destinationViewController setDelegate:self];
        [destinationViewController setType:kComposeTypeReply];
        [destinationViewController setBoardId:self.board.boardId];
        [destinationViewController setMessageId:message.messageId];
        [destinationViewController setSubject:subject];
    } else if ([segue.identifier isEqualToString:@"ModalToEditReply"]) {
        MCLComposeMessageViewController *destinationViewController = ((MCLComposeMessageViewController *)[[segue.destinationViewController viewControllers] objectAtIndex:0]);
        [destinationViewController setDelegate:self];
        [destinationViewController setType:kComposeTypeEdit];
        [destinationViewController setBoardId:self.board.boardId];
        [destinationViewController setMessageId:message.messageId];
        [destinationViewController setSubject:message.subject];
        [destinationViewController setText:message.text];
    } else if ([segue.identifier isEqualToString:@"ModalToShowProfile"]) {
        MCLProfileTableViewController *destinationViewController = ((MCLProfileTableViewController *)[[segue.destinationViewController viewControllers] objectAtIndex:0]);      
        [destinationViewController setUserId:message.userId];
        [destinationViewController setUsername:message.username];
    }
}


@end

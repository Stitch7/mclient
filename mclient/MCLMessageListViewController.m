//
//  MCLMessageListTableViewController.m
//  mclient
//
//  Created by Christopher Reitz on 25.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "constants.h"
#import "KeychainItemWrapper.h"
#import "MCLMServiceConnector.h"
#import "MCLMessageListViewController.h"
#import "MCLComposeMessageViewController.h"
#import "MCLProfileTableViewController.h"
#import "MCLDetailView.h"
#import "MCLLoadingView.h"
#import "MCLMessageTableViewCell.h"
#import "MCLBoard.h"
#import "MCLThread.h"
#import "MCLMessage.h"
#import "MCLReadList.h"


@interface MCLMessageListViewController ()

@property (strong, nonatomic) UIPopoverController *masterPopoverController;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong) UIRefreshControl *refreshControl;
@property (strong) UIColor *tableSeparatorColor;
@property (strong) MCLMServiceConnector *mServiceConnector;
@property (strong) NSMutableArray *messages;
@property (strong) NSMutableArray *cells;
@property (strong) MCLReadList *readList;
@property (strong) NSString *username;
@property (strong) NSString *password;
@property (strong) NSDateFormatter *dateFormatter;

@end

@implementation MCLMessageListViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.mServiceConnector = [[MCLMServiceConnector alloc] init];
    self.cells = [NSMutableArray array];
    self.readList = [[MCLReadList alloc] init];
    
    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:identifier accessGroup:nil];
    self.username = [keychainItem objectForKey:(__bridge id)(kSecAttrAccount)];
    NSData *passwordData = [keychainItem objectForKey:(__bridge id)(kSecValueData)];
    self.password = [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];
    
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

    // Init refresh control
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to refresh..."];
    [self.refreshControl addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];

    if (self.board && self.thread) {
        // Set title to threads subject
        self.title = self.thread.subject;

        // Preserve selection between presentations.
        //    self.clearsSelectionOnViewWillAppear = NO; //TODO

        // Add loading view
        [self.view addSubview:[[MCLLoadingView alloc] initWithFrame:self.view.bounds]];

        // Load data async
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData *data = [self loadData];
            [self performSelectorOnMainThread:@selector(fetchedData:) withObject:data waitUntilDone:YES];

            // Remove loading view on main thread
            dispatch_async(dispatch_get_main_queue(), ^{
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
        self.title = @"M!client";
        [self.view addSubview:[[MCLDetailView alloc] initWithFrame:self.view.bounds]];
    }
}

- (void)stopRefresh
{
    [self.refreshControl endRefreshing];
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
        [self performSelectorOnMainThread:@selector(fetchedData:) withObject:data waitUntilDone:YES];

        // Remove loading view on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
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
    NSString *urlString = [NSString stringWithFormat:@"%@board/%@/messagelist/%@", kMServiceBaseURL, self.board.boardId, self.thread.threadId];
    NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString: urlString]];

    return data;
}

- (void)reloadData
{
    NSData *data = [self loadData];
    [self fetchedData:data];
    [self performSelector:@selector(stopRefresh) withObject:nil afterDelay:1.5]; // 2.5
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
        NSUInteger level = [[object objectForKey:@"level"] integerValue];
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
                                                   text:nil];
        [self.messages addObject:message];
    }
    
    [self.tableView reloadData];
}

- (void)completeMessage:(MCLMessage *)message
{
    NSString *urlString = [NSString stringWithFormat:@"%@board/%@/message/%@", kMServiceBaseURL, self.board.boardId, message.messageId];
    NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString: urlString]];
    NSError* error;
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    message.userId = [json objectForKey:@"userId"];
    message.text = [json objectForKey:@"text"];
}


#pragma mark - UITableViewDelegate + UITableViewDataSource

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
//    NSLog(@"cellForRowAtIndexPath: %i", i);
    
    MCLMessage *message = self.messages[i];
    MCLMessage *nextMessage = nil;
    if (indexPath.row < ([self.messages count] - 1)) {
        nextMessage = self.messages[i + 1];
    }
    MCLMessageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MessageCell" forIndexPath:indexPath];
    
    [self.cells setObject:cell atIndexedSubscript:i];
    
    [cell setBoardId:self.board.boardId];
    [cell setMessageId:message.messageId];
//    cell.tag = i; //TODO not needed, i think...

    [cell setClipsToBounds:YES];
    
    [self indentView:cell.messageSubjectLabel withLevel:message.level startingAtX:20];
    [self indentView:cell.messageUsernameLabel withLevel:message.level startingAtX:20];
    [self indentView:(UIView*)cell.readSymbolView withLevel:message.level startingAtX:5];
    
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
    
    BOOL hideNotificationButton = ! [message.username isEqualToString:self.username];
    [self barButton:cell.messageNotificationButton hide:hideNotificationButton];
    
    if ( ! hideNotificationButton) {
        NSError *mServiceError;
        NSInteger notificationStatus = [self.mServiceConnector notificationStatusForMessageId:message.messageId
                                                                                      boardId:self.board.boardId
                                                                                     username:self.username
                                                                                     password:self.password
                                                                                        error:&mServiceError];
        [cell enableNotificationButton:notificationStatus];
    }
    
    BOOL hideEditButton = ! ([message.username isEqualToString:self.username] && nextMessage.level <= message.level);
    [self barButton:cell.messageEditButton hide:hideEditButton];
    
    [cell.messageToolbar setHidden:YES];
    
    return cell;
}

- (void)indentView:(UIView *)view withLevel:(int)level startingAtX:(CGFloat)x
{//TODO make level = NSNumber
    int indention = 10;
    
    CGRect frame = view.frame;
//    frame.origin = CGPointMake((indention * 2) + (indention * level), frame.origin.y);
//    frame.origin = CGPointMake(frame.origin.x + (indention * level), frame.origin.y);
    frame.origin = CGPointMake(x + (indention * level), frame.origin.y);
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 60;

	if ([tableView indexPathsForSelectedRows].count && [[tableView indexPathsForSelectedRows] indexOfObject:indexPath] != NSNotFound) {
        MCLMessageTableViewCell *cell = self.cells[indexPath.row];
        CGFloat webViewHeight = cell.messageTextWebView.scrollView.contentSize.height;
        CGFloat toolbarHeight = cell.messageToolbar.frame.size.height;
        height = 60 + 20 + webViewHeight + toolbarHeight;
//        NSLog(@"heightForRowAtIndexPath(%i - %i): %f  -  %f", cell.tag, indexPath.row, cell.messageTextWebView.frame.size.height, webViewHeight);
	}

    return height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
//    NSIndexPath *selectedRowIndexPath = [tableView indexPathForSelectedRow];
//    NSLog(@"indexPath: %i  -  selectedRowIndexPath:%i", indexPath.row, selectedRowIndexPath.row);
    
    MCLMessage *message = self.messages[indexPath.row];
    if (!message.text) {
        [self completeMessage:message];
    }
    
    MCLMessageTableViewCell *cell = (MCLMessageTableViewCell*)[tableView cellForRowAtIndexPath:indexPath];
    
    UIColor *veryLightGrey = [UIColor colorWithRed:240/255.0f green:240/255.0f blue:240/255.0f alpha:1.0f];
    [cell setBackgroundColor:veryLightGrey];
    [cell.messageTextWebView setBackgroundColor:veryLightGrey];
    
    [cell markRead];
    cell.messageText = message.text;
    
    NSString *messageHtml = [@""
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
        "        margin: 0px;"
        "    }"
        "    img {"
        "        max-width: 100%;"
        "    }"
        "    button > img {"
        "        content:url(\"http://www.maniac-forum.de/forum/images/spoiler.png\");"
        "        width: 17px;"
        "    }"
        "</style>" stringByAppendingString:message.text];
    [cell.messageTextWebView loadHTMLString:messageHtml baseURL:nil];
    
    [self.readList addMessageId:message.messageId];
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

-(BOOL) webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType {
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
    // Resize text view to content heigt
    CGSize webViewTextSize = [webView sizeThatFits:CGSizeMake(1.0f, 1.0f)];
    CGRect webViewFrame = webView.frame;
    webViewFrame.size.height = webViewTextSize.height;
    webView.frame = webViewFrame;
    
    // Disable bouncing in webview
    for (id subview in webView.subviews) {
        if ([[subview class] isSubclassOfClass: [UIScrollView class]]) {
            [subview setBounces:NO];
        }
    }

    // Resize table cell
    [self updateTableView];

    // Show toolbar after short delay to avoid skidding through text
    MCLMessageTableViewCell *cell = (MCLMessageTableViewCell *)webView.superview.superview.superview;
    [cell.messageToolbar performSelector:@selector(setHidden:) withObject:NO afterDelay:0.5];
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
        
        [destinationViewController setType:kComposeTypeReply];
        [destinationViewController setBoardId:self.board.boardId];
        [destinationViewController setMessageId:message.messageId];
        [destinationViewController setSubject:subject];
    } else if ([segue.identifier isEqualToString:@"ModalToEditReply"]) {
        MCLComposeMessageViewController *destinationViewController = ((MCLComposeMessageViewController *)[[segue.destinationViewController viewControllers] objectAtIndex:0]);
        
        MCLMessageTableViewCell *cell = (MCLMessageTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        NSString *text = [cell.messageTextWebView stringByEvaluatingJavaScriptFromString:@"document.getElementsByTagName(\"body\")[0].textContent;"];
        text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        [destinationViewController setType:kComposeTypeEdit];
        [destinationViewController setBoardId:self.board.boardId];
        [destinationViewController setMessageId:message.messageId];
        [destinationViewController setSubject:message.subject];
        [destinationViewController setText:text];
    } else if ([segue.identifier isEqualToString:@"ModalToShowProfile"]) {
        MCLProfileTableViewController *destinationViewController = ((MCLProfileTableViewController *)[[segue.destinationViewController viewControllers] objectAtIndex:0]);      
        [destinationViewController setUserId:message.userId];
        [destinationViewController setUsername:message.username];
    }
}


@end

//
//  MCLMessageList2FrameStyleViewController.m
//  mclient
//
//  Created by Christopher Reitz on 16.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "MCLMessageList2FrameStyleViewController.h"

#import "constants.h"
#import "KeychainItemWrapper.h"
#import "MCLMServiceConnector.h"
#import "MCLComposeMessageTableViewController.h"
#import "MCLProfileTableViewController.h"
#import "MCLLoadingView.h"
#import "MCLMessageTableViewCell.h"
#import "MCLBoard.h"
#import "MCLThread.h"
#import "MCLMessage.h"
#import "MCLReadList.h"

#pragma mark - Private Stuff
@interface MCLMessageList2FrameStyleViewController ()

@property (strong) MCLMServiceConnector *mServiceConnector;
@property (strong) NSMutableArray *messages;
@property (strong) NSMutableArray *cells;
@property (strong) MCLReadList *readList;
@property (strong) NSString *username;
@property (strong) NSString *password;
@property (strong) NSDateFormatter *dateFormatter;
@property (strong) NSIndexPath *selectedIndexPath;
@property (strong) UIRefreshControl *refreshControl;

@property (weak, nonatomic) IBOutlet UIView *messageView;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolbarButtonSpeak;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolbarButtonNotification;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolbarButtonEdit;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolbarButtonReply;

@property (strong, nonatomic) AVSpeechSynthesizer *speechSynthesizer;

@end

@implementation MCLMessageList2FrameStyleViewController

#pragma mark - ViewController
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

    // Set title to threads subject
    self.title = self.thread.subject;

    self.selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];

    // WebView setup
    self.webView.delegate = self;

    // Init toolbar slide gestures
    UISwipeGestureRecognizer *toolbarDownSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(slideMessageViewDownAction)];
    toolbarDownSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
    toolbarDownSwipeRecognizer.cancelsTouchesInView = YES;

    UISwipeGestureRecognizer *toolbarUpSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(slideMessageViewUpAction)];
    toolbarUpSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionUp;
    toolbarUpSwipeRecognizer.cancelsTouchesInView = YES;

    [self.toolbar addGestureRecognizer:toolbarDownSwipeRecognizer];
    [self.toolbar addGestureRecognizer:toolbarUpSwipeRecognizer];

    // Init refresh control
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];

    // Add loading view
    [self.view addSubview:[[MCLLoadingView alloc] initWithFrame:self.view.bounds]];

    // Load data async
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self performSelectorOnMainThread:@selector(fetchedData:) withObject:[self loadData] waitUntilDone:YES];

        // Remove loading view on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id subview in self.view.subviews) {
                if ([[subview class] isSubclassOfClass: [MCLLoadingView class]]) {
                    [subview removeFromSuperview];
                }
            }
        });
    });
}

- (CGFloat)fullViewheight
{
    return self.view.bounds.size.height - self.navigationController.navigationBar.bounds.size.height - [UIApplication sharedApplication].statusBarFrame.size.height;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Data methods

- (NSData *)loadData
{
    NSString *urlString = [NSString stringWithFormat:@"%@board/%@/messagelist/%@", kMServiceBaseURL, self.board.boardId, self.thread.threadId];
    NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString: urlString]];

    return data;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    // Fixes refreshcontrol's too litle space problem
    if (scrollView.contentOffset.y < -55 && ! [self.refreshControl isRefreshing]) {
        [self.refreshControl beginRefreshing];
        [self reloadData];
    }
}

- (void)reloadData
{
    NSData *data = [self loadData];
    [self fetchedData:data];
    [self.refreshControl performSelector:@selector(endRefreshing) withObject:nil afterDelay:1.5]; // 2.5
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

    [self.tableView selectRowAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:0];
    [self tableView:self.tableView didSelectRowAtIndexPath:self.selectedIndexPath];
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

    if (i == 0 || [self.readList messageIdIsRead:message.messageId]) {
        [cell markRead];
    } else {
        [cell markUnread];
    }

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


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedIndexPath = indexPath;
    NSInteger i = indexPath.row;

    MCLMessage *message = self.messages[i];
    if ( ! message.text) {
        [self completeMessage:message];
    }

    MCLMessage *nextMessage = nil;
    if (indexPath.row < ([self.messages count] - 1)) {
        nextMessage = self.messages[i + 1];
    }

    MCLMessageTableViewCell *cell = (MCLMessageTableViewCell*)[tableView cellForRowAtIndexPath:indexPath];

    [cell markRead];
    [self.readList addMessageId:message.messageId];
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
                             "    }"
                             "    body {"
                             "        margin: 10px;"
                             "        padding: 0px;"
                             "    }"
                             "    img {"
                             "        width: 100%;"
                             "    }"
                             "    a {"
                             "        word-break: break-all;"
                             "    }"
                             "    button > img {"
                             "        content:url(\"http://www.maniac-forum.de/forum/images/spoiler.png\");"
                             "        width: 17px;"
                             "    }"
                             "</style>" stringByAppendingString:message.text];
    [self.webView loadHTMLString:messageHtml baseURL:nil];



    BOOL enableNotificationButton = [message.username isEqualToString:self.username];
    [self.toolbarButtonNotification setEnabled:enableNotificationButton];

    if (enableNotificationButton) {
        NSError *mServiceError;
        NSInteger notificationStatus = [self.mServiceConnector notificationStatusForMessageId:message.messageId
                                                                                      boardId:self.board.boardId
                                                                                     username:self.username
                                                                                     password:self.password
                                                                                        error:&mServiceError];

        if (notificationStatus) {
            self.toolbarButtonNotification.image = [UIImage imageNamed:@"notificationButtonEnabled.png"];
            self.toolbarButtonNotification.tag = 1;
        } else {
            self.toolbarButtonNotification.image = [UIImage imageNamed:@"notificationButtonDisabled.png"];
            self.toolbarButtonNotification.tag = 0;
        }
    }

    BOOL enableEditButton = [message.username isEqualToString:self.username] && nextMessage.level <= message.level;
    [self.toolbarButtonEdit setEnabled:enableEditButton];
}


#pragma mark - UIWebView delegate

-(BOOL) webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType {
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



#pragma mark - Actions

- (void)slideMessageViewDownAction
{
    self.messageView.layer.needsDisplayOnBoundsChange = YES;
    self.messageView.contentMode = UIViewContentModeRedraw;

    // Cache initial height
    [self.messageView setTag:self.messageView.bounds.size.height];

    [UIView animateWithDuration:.4f animations:^{
        CGRect bounds = self.messageView.bounds;
        CGPoint center = self.messageView.center;
        bounds.size.height += [self fullViewheight] - self.messageView.bounds.size.height;
        center.y += ([self fullViewheight] - self.messageView.bounds.size.height) / 2;
        self.messageView.bounds = bounds;
        self.messageView.center = center;
    }];

    self.messageView.layer.needsDisplayOnBoundsChange = NO;
}

- (void)slideMessageViewUpAction
{
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
}

- (IBAction)copyLinkAction:(UIBarButtonItem *)sender
{
    MCLMessage *message = self.messages[self.selectedIndexPath.row];

    NSString *link = [NSString stringWithFormat:@"%@?mode=message&brdid=%@&msgid=%@", kManiacForumURL, self.board.boardId, message.messageId];

    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = link;

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success"
                                                    message:@"Copied link to this message to clipboard"
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
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
        MCLMessageTableViewCell *selectedCell = (MCLMessageTableViewCell*)[self.tableView cellForRowAtIndexPath:self.selectedIndexPath];

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
        [utterance setRate:AVSpeechUtteranceDefaultSpeechRate];
        [self.speechSynthesizer speakUtterance:utterance];
    }
}

- (IBAction)notificationAction:(UIBarButtonItem *)sender
{
    MCLMessage *message = self.messages[self.selectedIndexPath.row];

    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:identifier accessGroup:nil];
    NSString *username = [keychainItem objectForKey:(__bridge id)(kSecAttrAccount)];
    NSData *passwordData = [keychainItem objectForKey:(__bridge id)(kSecValueData)];
    NSString *password = [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];

    MCLMServiceConnector *mServiceConnector = [[MCLMServiceConnector alloc] init];
    NSError *mServiceError;
    BOOL success = [mServiceConnector notificationForMessageId:message.messageId boardId:self.board.boardId username:username password:password error:&mServiceError];

    NSString *alertTitle, *alertMessage;

    if ( ! success) {
        alertTitle = [mServiceError localizedDescription];
        alertMessage = [mServiceError localizedFailureReason];
    } else if (sender.tag == 1) {
        [sender setTag:0];
        self.toolbarButtonNotification.image = [UIImage imageNamed:@"notificationButtonDisabled.png"];
        alertTitle = @"Message notification disabled";
        alertMessage = @"You will no longer receive Emails if anyone replies to this post.";
    } else {
        [sender setTag:1];
        self.toolbarButtonNotification.image = [UIImage imageNamed:@"notificationButtonEnabled.png"];
        alertTitle = @"Message notification enabled";
        alertMessage = @"You will receive an Email if anyone answers to this post.";
    }

    [[[UIAlertView alloc] initWithTitle:alertTitle
                                message:alertMessage
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    MCLMessage *message = self.messages[indexPath.row];

    if ([segue.identifier isEqualToString:@"ModalToComposeReply"]) {
        MCLComposeMessageTableViewController *destinationViewController = ((MCLComposeMessageTableViewController *)[[segue.destinationViewController viewControllers] objectAtIndex:0]);
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
        MCLComposeMessageTableViewController *destinationViewController = ((MCLComposeMessageTableViewController *)[[segue.destinationViewController viewControllers] objectAtIndex:0]);

        NSString *text = [self.webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByTagName(\"body\")[0].textContent;"]; //TODO looses Images...
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

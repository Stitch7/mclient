//
//  MCLResponsesTableViewController.m
//  mclient
//
//  Created by Christopher Reitz on 24/02/2017.
//  Copyright © 2017 Christopher Reitz. All rights reserved.
//

#import "MCLResponsesTableViewController.h"

#import "constants.h"
#import "KeychainItemWrapper.h"
#import "MCLAppDelegate.h"
#import "MCLMServiceConnector.h"
#import "MCLMessageListViewController.h"
#import "MCLThemeManager.h"
#import "MCLMServiceErrorView.h"
#import "MCLInternetConnectionErrorView.h"
#import "MCLLoadingView.h"
#import "MCLMessageListFrameStyleTableViewCell.h"
#import "MCLBoard.h"
#import "MCLThread.h"
#import "MCLResponse.h"


@interface MCLResponsesTableViewController ()

@property (strong, nonatomic) MCLMessageListViewController *detailViewController;
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (strong, nonatomic) id <MCLTheme> currentTheme;
@property (strong, nonatomic) NSMutableDictionary *responses;
@property (strong, nonatomic) NSMutableArray *sectionKeys;
@property (strong, nonatomic) NSMutableDictionary *sectionTitles;
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation MCLResponsesTableViewController

#pragma mark - Initializers

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UIViewController

- (void)awakeFromNib
{
    [super awakeFromNib];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(themeChanged:)
                                                 name:MCLThemeChangedNotification
                                               object:nil];

    self.currentTheme = [[MCLThemeManager sharedManager] currentTheme];

    NSString *keychainIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:keychainIdentifier
                                                                            accessGroup:nil];
    self.username = [keychainItem objectForKey:(__bridge id)(kSecAttrAccount)];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
    }

    // Init + setup dateformatter for message dates
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDoesRelativeDateFormatting:YES];
    [self.dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [self.dateFormatter setTimeStyle:NSDateFormatterShortStyle];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    UINib *responseCellNib = [UINib nibWithNibName: @"MCLMessageListFrameStyleTableViewCell" bundle: nil];
    [self.tableView registerNib: responseCellNib forCellReuseIdentifier: @"ResponseCell"];

    // On iPad replace splitviews detailViewController with MessageListViewController type depending on users settings
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        NSString *storyboardIdentifier = nil;
        switch ([[NSUserDefaults standardUserDefaults] integerForKey:@"threadView"]) {
            case kMCLSettingsThreadViewWidmann:
            default:
                storyboardIdentifier = @"MessageListWidmannStyleView";
                break;

            case kMCLSettingsThreadViewFrame:
                storyboardIdentifier = @"MessageListFrameStyleView";
                break;
        }
        self.detailViewController = [self.storyboard instantiateViewControllerWithIdentifier:storyboardIdentifier];

        UINavigationController *navController = [self.splitViewController.viewControllers lastObject];
        MCLMessageListViewController *oldController = [navController.viewControllers firstObject];
        [navController setViewControllers:[NSArray arrayWithObjects:self.detailViewController, nil]];
        UIBarButtonItem *splitViewButton = oldController.navigationItem.leftBarButtonItem;
        self.masterPopoverController = oldController.masterPopoverController;
        [self.detailViewController setSplitViewButton:splitViewButton forPopoverController:self.masterPopoverController];
    }

    UIBarButtonItem *downButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"downButton.png"]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(downButtonPressed)];
    self.navigationItem.leftBarButtonItem = downButton;

    // Cache original tables separatorColor and set to clear to avoid flickering loading view
    [self.tableView setSeparatorColor:[UIColor clearColor]];

    // Set title to board name
    self.title = @"Letzte Antworten"; // TODO: i18n

    // Init refresh control
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;

    // Visualize loading
    MCLLoadingView *loadingView = [[MCLLoadingView alloc] initWithFrame:self.view.frame];
    [self.tableView addSubview:loadingView];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    // Load data async
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *mServiceError;
        NSDictionary *data = [[MCLMServiceConnector sharedConnector] responsesForUsername:self.username
                                                                                    error:&mServiceError];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self fetchedData:data error:mServiceError];
        });
    });
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.currentTheme = [[MCLThemeManager sharedManager] currentTheme];

    // Fix odd glitch on swipe back causing cell stay selected
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (selectedIndexPath) {
        [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
    }

    [self.tableView reloadData];

    [self.navigationController setToolbarHidden:YES animated:NO];
}

- (void)downButtonPressed
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)reloadData
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *mServiceError;
        NSDictionary *data = [[MCLMServiceConnector sharedConnector] responsesForUsername:self.username
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
            [[subview class] isSubclassOfClass: [MCLLoadingView class]]
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

        NSDateFormatter *dateKeyFormatter = [[NSDateFormatter alloc] init];
        [dateKeyFormatter setDateFormat: @"yyyy-MM-dd"];

        NSDateFormatter *dateStrFormatter = [[NSDateFormatter alloc] init];
        [dateStrFormatter setDoesRelativeDateFormatting:YES];
        [dateStrFormatter setDateStyle:NSDateFormatterShortStyle];
        [dateStrFormatter setTimeStyle:NSDateFormatterNoStyle];

        self.sectionKeys = [NSMutableArray array];
        self.sectionTitles = [NSMutableDictionary dictionary];
        NSMutableDictionary *responses = [NSMutableDictionary dictionary];
        for (id object in data) {
            NSNumber *boardId = [object objectForKey:@"boardId"];
            NSNumber *threadId = [object objectForKey:@"threadId"];
            NSString *threadSubject = [object objectForKey:@"threadSubject"];
            NSNumber *messageId = [object objectForKey:@"messageId"];
            id isReadOpt = [object objectForKey:@"isRead"];
            BOOL isRead = (isReadOpt != (id)[NSNull null] && isReadOpt != nil) ? [isReadOpt boolValue] : YES;
            NSString *username = [object objectForKey:@"username"];
            NSString *subject = [object objectForKey:@"subject"];
            NSDate *date = [dateFormatter dateFromString:[object objectForKey:@"date"]];

            NSString *sectionKey = [[dateKeyFormatter stringFromDate:date] stringByAppendingString:threadSubject];

            NSMutableArray *responsesWithKey = [NSMutableArray array];
            if (![self.sectionKeys containsObject:sectionKey]) {
                [self.sectionKeys addObject:sectionKey];
                NSString *dateStr = [dateStrFormatter stringFromDate:date];
                NSString *sectionTitle = [[dateStr stringByAppendingString:@": "] stringByAppendingString:threadSubject];
                [self.sectionTitles setObject:sectionTitle forKey:sectionKey];
            }
            else {
                responsesWithKey = [self.responses objectForKey:sectionKey];
            }

            MCLResponse *response = [MCLResponse responseWithBoardId:boardId
                                                            threadId:threadId
                                                       threadSubject:threadSubject
                                                           messageId:messageId
                                                             subject:subject
                                                            username:username
                                                                date:date
                                                                read:isRead];
            [responsesWithKey addObject:response];

            NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
            NSMutableArray *sortedResponsesWithKey = [NSMutableArray arrayWithArray:[responsesWithKey sortedArrayUsingDescriptors:@[descriptor]]];

            [responses setObject:sortedResponsesWithKey forKey:sectionKey];
            self.responses = responses;
        }

        NSArray *sortedSections = [self.sectionKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        self.sectionKeys = [NSMutableArray arrayWithArray:[[sortedSections reverseObjectEnumerator] allObjects]];

        // Restore tables separatorColor
        [self.tableView setSeparatorColor:[self.currentTheme tableViewSeparatorColor]];

        [self.tableView reloadData];
    }
}

#pragma mark - UITableViewDataSource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.sectionKeys count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *messagesInSection = [self.responses objectForKey:[self.sectionKeys objectAtIndex:section]];
    return [messagesInSection count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.sectionTitles objectForKey:[self.sectionKeys objectAtIndex:section]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *messagesInSection = [self.responses objectForKey:[self.sectionKeys objectAtIndex:indexPath.section]];
    MCLResponse *response = messagesInSection[indexPath.row];

    static NSString *cellIdentifier = @"ResponseCell";
    MCLMessageListFrameStyleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    [cell setBoardId:response.boardId];
    [cell setMessageId:response.messageId];

    UIView *backgroundView = [[UIView alloc] initWithFrame:cell.frame];
    backgroundView.backgroundColor = [self.currentTheme tableViewCellSelectedBackgroundColor];
    cell.selectedBackgroundView = backgroundView;

    cell.messageIndentionImageView.image = [cell.messageIndentionImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    cell.messageIndentionImageView.tintColor = [self.currentTheme tableViewSeparatorColor];

    cell.messageIndentionView.backgroundColor = cell.backgroundColor;

    cell.messageSubjectLabel.text = response.subject;
    cell.messageSubjectLabel.textColor = [self.currentTheme textColor];

    cell.messageUsernameLabel.text = response.username;
    cell.messageUsernameLabel.textColor = [self.currentTheme usernameTextColor];

    cell.messageDateLabel.text = [self.dateFormatter stringFromDate:response.date];
    cell.messageDateLabel.textColor = [self.currentTheme detailTextColor];

    if (response.isRead || response.isTemporaryRead) {
        [cell markRead];
    } else {
        [cell markUnread];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

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
    NSArray *messagesInSection = [self.responses objectForKey:[self.sectionKeys objectAtIndex:indexPath.section]];
    MCLResponse *response = messagesInSection[indexPath.row];
    MCLMessageListFrameStyleTableViewCell *cell = (MCLMessageListFrameStyleTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell markRead];
    response.tempRead = YES;

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        // Hide popoverController in portrait mode
        if (!UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])) {
            [self.masterPopoverController dismissPopoverAnimated:YES];
        }

        MCLThread *thread = [MCLThread threadWithId:response.threadId
                                            subject:response.threadSubject];
        MCLBoard *board = [MCLBoard boardWithId:response.boardId name:nil];
        [self.detailViewController setJumpToMessageId:response.messageId];
        [self.detailViewController loadThread:thread fromBoard:board];
    }
    else {
        NSString *segueIdentifier = nil;
        switch ([[NSUserDefaults standardUserDefaults] integerForKey:@"threadView"]) {
            case kMCLSettingsThreadViewWidmann:
            default:
                segueIdentifier = @"PushToMessageListWidmannStyle";
                break;

            case kMCLSettingsThreadViewFrame:
                segueIdentifier = @"PushToMessageListFrameStyle";
                break;
        }

        [self performSegueWithIdentifier:segueIdentifier sender:cell];
    }
}

#pragma mark - Notifications

- (void)themeChanged:(NSNotification *)notification
{
    self.currentTheme = [[MCLThemeManager sharedManager] currentTheme];
    [self.tableView setSeparatorColor:[self.currentTheme tableViewSeparatorColor]];
    [self.tableView reloadData];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"PushToMessageListWidmannStyle"] ||
        [segue.identifier isEqualToString:@"PushToMessageListFrameStyle"]
    ) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];

        NSArray *messagesInSection = [self.responses objectForKey:[self.sectionKeys objectAtIndex:indexPath.section]];
        MCLResponse *response = messagesInSection[indexPath.row];
        MCLBoard *board = [MCLBoard boardWithId:response.boardId name:nil];
        MCLThread *thread = [MCLThread threadWithId:response.threadId
                                            subject:response.threadSubject];

        MCLMessageListViewController *messageListVC = segue.destinationViewController;
        [messageListVC setBoard:board];
        [messageListVC setThread:thread];
        [messageListVC setJumpToMessageId:response.messageId];
    }
}

@end

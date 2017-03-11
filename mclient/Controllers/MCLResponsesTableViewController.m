//
//  MCLResponsesTableViewController.m
//  mclient
//
//  Created by Christopher Reitz on 24/02/2017.
//  Copyright © 2017 Christopher Reitz. All rights reserved.
//

#import "MCLResponsesTableViewController.h"

#import "UIView+addConstraints.h"
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
#import "MCLNotificationHistory.h"


@interface MCLResponsesTableViewController ()

@property (strong, nonatomic) MCLMessageListViewController *detailViewController;
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (strong, nonatomic) id <MCLTheme> currentTheme;
@property (strong, nonatomic) MCLMessageResponsesClient *messageResponsesClient;
@property (strong, nonatomic) NSDictionary *responses;
@property (strong, nonatomic) NSArray *sectionKeys;
@property (strong, nonatomic) NSDictionary *sectionTitles;
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

    self.messageResponsesClient = [MCLMessageResponsesClient sharedClient];

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
    [self.tableView registerNib:responseCellNib forCellReuseIdentifier:@"ResponseCell"];

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

    self.tableView.sectionHeaderHeight = UITableViewAutomaticDimension;

    // Set title to board name
    self.title = NSLocalizedString(@"Replies to your posts", nil);

    // Init refresh control
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;

    // Visualize loading
    MCLLoadingView *loadingView = [[MCLLoadingView alloc] initWithFrame:self.view.frame];
    [self.tableView addSubview:loadingView];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    [self reloadData];
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

- (void)removeOverlayViews
{
    for (id subview in self.view.subviews) {
        if ([[subview class] isSubclassOfClass: [MCLErrorView class]] ||
            [[subview class] isSubclassOfClass: [MCLLoadingView class]]
        ) {
            [subview removeFromSuperview];
        }
    }
}

- (void)reloadData
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self.messageResponsesClient loadDataWithCompletion:^(NSDictionary *responses, NSArray *sectionKeys, NSDictionary *sectionTitles) {
        self.responses = responses;
        self.sectionKeys = sectionKeys;
        self.sectionTitles = sectionTitles;

        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [self removeOverlayViews];
        if (self.refreshControl.isRefreshing) {
            [self.refreshControl endRefreshing];
        }

        [self.tableView setSeparatorColor:[self.currentTheme tableViewSeparatorColor]];
        [self.tableView reloadData];
    }];
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

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGFloat x = 10.0f;
    CGFloat height = 25.0f;
    CGFloat width = self.tableView.frame.size.width - x;
    NSDictionary *titleDic = [self.sectionTitles objectForKey:[self.sectionKeys objectAtIndex:section]];

    UILabel *dateLabel = [[UILabel alloc] init];
    dateLabel.frame = CGRectMake(x, 5, width, height);
    dateLabel.font = [UIFont boldSystemFontOfSize:12.0f];
    dateLabel.textColor = [self.currentTheme tableViewHeaderTextColor];
    dateLabel.text = [[titleDic objectForKey:@"date"] uppercaseString];

    UILabel *subjectLabel = [[UILabel alloc] init];
    CGFloat yOffset = height - 2.0f;
    subjectLabel.frame = CGRectMake(x, yOffset, width, height);
    subjectLabel.font = [UIFont systemFontOfSize:14.0f];
    subjectLabel.textColor = [self.currentTheme tableViewHeaderTextColor];
    subjectLabel.text = [titleDic objectForKey:@"subject"];

    UIView *header = [[UIView alloc] init];
    [header addSubview:dateLabel];
    [header addSubview:subjectLabel];

    return header;
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *messagesInSection = [self.responses objectForKey:[self.sectionKeys objectAtIndex:indexPath.section]];
    MCLResponse *response = messagesInSection[indexPath.row];
    MCLMessageListFrameStyleTableViewCell *cell = (MCLMessageListFrameStyleTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell markRead];
    response.tempRead = YES;

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

        [[MCLNotificationHistory sharedNotificationHistory] removeResponse:response];
    }
}

@end

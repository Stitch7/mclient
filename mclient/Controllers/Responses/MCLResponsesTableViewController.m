//
//  MCLResponsesTableViewController.m
//  mclient
//
//  Copyright © 2014 - 2017 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLResponsesTableViewController.h"

#import "MCLDependencyBag.h"
#import "UIViewController+Additions.h"
#import "UIView+addConstraints.h"
#import "MCLRouter+mainNavigation.h"
#import "MCLLogin.h"
#import "MCLMarkUnreadResponsesAsReadRequest.h"
#import "MCLMessageListViewController.h"
#import "MCLThemeManager.h"
#import "MCLMServiceErrorView.h"
#import "MCLInternetConnectionErrorView.h"
#import "MCLLoadingView.h"
#import "MCLMessageListFrameStyleTableViewCell.h"
#import "MCLBoard.h"
#import "MCLThread.h"
#import "MCLResponse.h"
#import "MCLMessage.h"
#import "MCLNotificationHistory.h"


@interface MCLResponsesTableViewController ()

@property (strong, nonatomic) MCLMessageListViewController *detailViewController;
@property (strong, nonatomic) id <MCLTheme> currentTheme;
@property (strong, nonatomic) MCLMessageResponsesRequest *messageResponsesRequest;
@property (strong, nonatomic) MCLResponseContainer *responseContainer;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation MCLResponsesTableViewController

#pragma mark - Initializers

// TODO: - We get launched via storyboard atm
- (instancetype)initWithBag:(id <MCLDependencyBag>)bag
{
    self = [super init];
    if (!self) return nil;

    self.bag = bag;
//    [self initialize];

    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UIViewController life cycle

- (void)awakeFromNib
{
    [super awakeFromNib];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(themeChanged:)
                                                 name:MCLThemeChangedNotification
                                               object:nil];

    self.currentTheme = self.bag.themeManager.currentTheme;
    self.messageResponsesRequest = [[MCLMessageResponsesRequest alloc] init];

    // Init + setup dateformatter for message dates
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDoesRelativeDateFormatting:YES];
    [self.dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [self.dateFormatter setTimeStyle:NSDateFormatterShortStyle];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self configureNaigationBar];
    [self configureTableView];

    // Visualize loading
    MCLLoadingView *loadingView = [[MCLLoadingView alloc] initWithFrame:self.view.frame];
    [self.tableView addSubview:loadingView];

    [self reloadData];
}

- (void)configureNaigationBar
{
    self.title = NSLocalizedString(@"Replies to your posts", nil);

    if ([self isModal]) {
        UIBarButtonItem *downButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"downButton"]
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(downButtonPressed)];
        self.navigationItem.leftBarButtonItem = downButton;
    }

    UIBarButtonItem *markAllAsReadButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"markAsRead"]
                                                              landscapeImagePhone:nil
                                                                            style:UIBarButtonItemStylePlain
                                                                           target:self
                                                                           action:@selector(markAllAsReadButtonButtonPressed)];

    BOOL markAllAsReadButtonIsEnabled = [UIApplication sharedApplication].applicationIconBadgeNumber > 0;
    [markAllAsReadButton setEnabled:markAllAsReadButtonIsEnabled];
    self.navigationItem.rightBarButtonItem = markAllAsReadButton;
}

- (void)configureTableView
{
    self.tableView.sectionHeaderHeight = UITableViewAutomaticDimension;

    UINib *responseCellNib = [UINib nibWithNibName: @"MCLMessageListFrameStyleTableViewCell" bundle: nil];
    [self.tableView registerNib:responseCellNib forCellReuseIdentifier:@"ResponseCell"];

    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}

#pragma mark - Actions

- (void)markAllAsReadButtonButtonPressed
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Confirmation", nil)
                                                                   message:NSLocalizedString(@"Mark all runread responses as read?", nil)
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                       style:UIAlertActionStyleCancel
                                                     handler:^(UIAlertAction * action) {
                                                         [alert dismissViewControllerAnimated:YES completion:nil];
                                                     }];

    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"mark as read", nil)
                                                       style:UIAlertActionStyleDestructive
                                                     handler:^(UIAlertAction * action) {
                                                         [self markUnreadResponsesAsRead];
                                                         [alert dismissViewControllerAnimated:YES completion:nil];
                                                     }];

    [alert addAction:cancelAction];
    [alert addAction:okAction];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)markUnreadResponsesAsRead
{
    MCLMarkUnreadResponsesAsReadRequest *request = [[MCLMarkUnreadResponsesAsReadRequest alloc] initWithClient:self.bag.httpClient
                                                                                                         login:self.bag.login];
    [request loadWithCompletionHandler:^(NSError *error, NSArray *response) {
        if (error) {
            NSLog(@"%@", error);
            return;
        }

        [self.navigationItem.rightBarButtonItem setEnabled:NO];
        [self reloadData];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.tableView reloadData];
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
    [self.messageResponsesRequest loadResponsesWithCompletion:^(NSError *error, MCLResponseContainer *responseContainer) {
        if (error) {
            return;
        }

        self.responseContainer = responseContainer;

        [self removeOverlayViews];
        if (self.refreshControl.isRefreshing) {
            [self.refreshControl endRefreshing];
        }

        [self.tableView setSeparatorColor:[self.currentTheme tableViewSeparatorColor]];
        [self.tableView reloadData];
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.responseContainer.sectionKeys count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.responseContainer messagesInSection:section] count];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGFloat x = 10.0f;
    CGFloat height = 25.0f;
    CGFloat width = self.tableView.frame.size.width - x;
    NSDictionary *titleDic = [self.responseContainer.sectionTitles objectForKey:[self.responseContainer.sectionKeys objectAtIndex:section]];

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
    MCLResponse *response = [self.responseContainer responseForIndexPath:indexPath];

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
    MCLResponse *response = [self.responseContainer responseForIndexPath:indexPath];
    MCLMessageListFrameStyleTableViewCell *cell = (MCLMessageListFrameStyleTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell markRead];
    response.tempRead = YES;

    [self.bag.router pushToMessage:[MCLMessage messageFromResponse:response] onMasterNavigationController:self.navigationController];
}

#pragma mark - Notifications

- (void)themeChanged:(NSNotification *)notification
{
    self.currentTheme = self.bag.themeManager.currentTheme;
    [self.tableView setSeparatorColor:[self.currentTheme tableViewSeparatorColor]];
    [self.tableView reloadData];
}

@end

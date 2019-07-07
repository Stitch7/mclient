//
//  MCLResponsesTableViewController.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLResponsesTableViewController.h"

#import <MRProgress.h>
#import "MCLDependencyBag.h"
#import "UIViewController+Additions.h"
#import "UIView+addConstraints.h"
#import "MCLRouter+mainNavigation.h"
#import "MCLMarkUnreadResponsesAsReadRequest.h"
#import "MCLLoadingViewController.h"
#import "MCLMessageListViewController.h"
#import "MCLThemeManager.h"
#import "MCLSoundEffectPlayer.h"
#import "MCLMessageListFrameStyleTableViewCell.h"
#import "MCLBoard.h"
#import "MCLThread.h"
#import "MCLResponse.h"
#import "MCLMessage.h"
#import "MCLNotificationHistory.h"


@interface MCLResponsesTableViewController ()

@property (strong, nonatomic) id <MCLDependencyBag> bag;
@property (strong, nonatomic) MCLMessageListViewController *detailViewController;
@property (strong, nonatomic) id <MCLTheme> currentTheme;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation MCLResponsesTableViewController

#pragma mark - Lazy Properties

- (NSDateFormatter *)dateFormatter
{
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.doesRelativeDateFormatting = YES;
        _dateFormatter.dateStyle = NSDateFormatterShortStyle;
        _dateFormatter.timeStyle = NSDateFormatterShortStyle;
    }

    return _dateFormatter;
}

#pragma mark - Initializers

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (!self) return nil;

    self.bag = bag;
    [self initialize];

    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)initialize
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(themeChanged:)
                                                 name:MCLThemeChangedNotification
                                               object:nil];

    self.currentTheme = self.bag.themeManager.currentTheme;
}

#pragma mark - UIViewController life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self configureTableView];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [self.tableView reloadData];
}

- (void)configureTableView
{
    self.tableView.sectionHeaderHeight = UITableViewAutomaticDimension;

    UINib *responseCellNib = [UINib nibWithNibName:@"MCLMessageListFrameStyleTableViewCell" bundle:nil];
    [self.tableView registerNib:responseCellNib forCellReuseIdentifier:@"ResponseCell"];
}

#pragma mark - Actions

- (void)markAllAsReadButtonButtonPressed
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Confirmation", nil)
                                                                   message:NSLocalizedString(@"Mark all unread responses as read?", nil)
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
    MRProgressOverlayView *progressView = [MRProgressOverlayView showOverlayAddedTo:self.view animated:YES];
    progressView.mode = MRProgressOverlayViewModeIndeterminateSmallDefault;
    progressView.titleLabelText = NSLocalizedString(@"Loading…", nil);
    MCLMarkUnreadResponsesAsReadRequest *request = [[MCLMarkUnreadResponsesAsReadRequest alloc] initWithClient:self.bag.httpClient
                                                                                                  loginManager:self.bag.loginManager];
    [request loadWithCompletionHandler:^(NSError *error, NSArray *response) {
        [MRProgressOverlayView dismissOverlayForView:self.view animated:YES];

        if (error) {
            [self presentAlertWithError:error];
            return;
        }

        [self.loadingViewController.navigationItem.rightBarButtonItem setEnabled:NO];
        [self.loadingViewController refresh];

        [self.bag.soundEffectPlayer playMarkAllAsReadSound];
    }];
}

- (void)downButtonPressed
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Helper

- (void)presentAlertWithError:(NSError *)error
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                   message:[error localizedDescription]
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
                                                         [alert dismissViewControllerAnimated:YES completion:nil];
                                                     }];
    [alert addAction:okAction];

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - MCLLoadingContentViewControllerDelegate

- (NSString *)loadingViewControllerRequestsTitleString:(MCLLoadingViewController *)loadingViewController
{
    return NSLocalizedString(@"Replies to your posts", nil);
}

- (void)loadingViewController:(MCLLoadingViewController *)loadingViewController configureNavigationItem:(UINavigationItem *)navigationItem
{
    UIBarButtonItem *markAllAsReadButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"markAsRead"]
                                                              landscapeImagePhone:nil
                                                                            style:UIBarButtonItemStylePlain
                                                                           target:self
                                                                           action:@selector(markAllAsReadButtonButtonPressed)];
    [markAllAsReadButton setEnabled:NO];
    navigationItem.rightBarButtonItem = markAllAsReadButton;
}

- (void)loadingViewController:(MCLLoadingViewController *)loadingViewController hasRefreshedWithData:(NSArray *)newData forKey:(NSNumber *)key
{
    self.responseContainer = [newData firstObject];

    BOOL markAllAsReadButtonIsEnabled = [self.responseContainer numberOfUnreadResponses] > 0;
    [self.loadingViewController.navigationItem.rightBarButtonItem setEnabled:markAllAsReadButtonIsEnabled];

    [self.tableView reloadData];
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
    if (@available(iOS 11.0, *)) {
        x += self.view.safeAreaInsets.left;
    }
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

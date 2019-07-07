//
//  MCLBoardListTableViewController.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLBoardListTableViewController.h"

#import "BBBadgeBarButtonItem.h"
#import "UIView+addConstraints.h"
#import "UIViewController+Additions.h"
#import "MCLDependencyBag.h"
#import "MCLFeatures.h"
#import "MCLFavoriteThreadToggleRequest.h"
#import "MCLRouter+mainNavigation.h"
#import "MCLRouter+privateMessages.h"
#import "MCLLoginManager.h"
#import "MCLMessageResponsesRequest.h"
#import "MCLTheme.h"
#import "MCLThemeManager.h"
#import "MCLKeyboardShortcutManager.h"
#import "MCLPrivateMessagesManager.h"
#import "MCLStoreReviewManager.h"
#import "MCLSoundEffectPlayer.h"
#import "MCLSplitViewController.h"
#import "MCLThreadListTableViewController.h"
#import "MCLMessageListViewController.h"
#import "MCLBoard.h"
#import "MCLBoardTableViewCell.h"
#import "MCLThread.h"
#import "MCLThreadTableViewCell.h"
#import "MCLLogoLabel.h"
#import "MCLVerifyLoginView.h"
#import "MCLNoDataInfo.h"
#import "MCLNoDataView.h"
#import "MCLNoDataTableViewCell.h"
#import "MCLSettings.h"
#import "MCLSettings+Keys.h"
#import "MCLDraftManager.h"


@interface MCLBoardListTableViewController ()

@property (strong, nonatomic) id <MCLDependencyBag> bag;
@property (strong, nonatomic) NSArray *boards;
@property (strong, nonatomic) NSMutableArray *favorites;
@property (strong, nonatomic) MCLMessageListViewController *detailViewController;
@property (strong, nonatomic) id <MCLTheme> currentTheme;
@property (strong, nonatomic) BBBadgeBarButtonItem *responsesButtonItem;
@property (strong, nonatomic) BBBadgeBarButtonItem *privateMessagesButtonItem;
@property (strong, nonatomic) MCLVerifyLoginView *verifyLoginView;
@property (assign, nonatomic) BOOL alreadyAppeared;
@property (assign, nonatomic) BOOL temporarilyDontShowNoFavoritesView;

@end

@implementation MCLBoardListTableViewController

#pragma mark - Initializers

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (!self) return nil;

    self.bag = bag;
    self.currentTheme = self.bag.themeManager.currentTheme;
    self.alreadyAppeared = NO;
    self.temporarilyDontShowNoFavoritesView = YES;
    [self configureNotifications];
    [self configureToolbarButtons];

    return self;
}

- (void)configureNotifications
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(loginStateDidChanged:)
                               name:MCLLoginStateDidChangeNotification
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(themeChanged:)
                               name:MCLThemeChangedNotification
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(foundUnreadResponses:)
                               name:MCLUnreadResponsesFoundNotification
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(draftsChanged:)
                               name:MCLDraftsChangedNotification
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(privateMessagesChanged:)
                               name:MCLPrivateMessagesChangedNotification
                             object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Lazy Properties

- (MCLVerifyLoginView *)verifyLoginView
{
    if (!_verifyLoginView) {
        MCLVerifyLoginView *verifyLoginView = [[MCLVerifyLoginView alloc] initWithThemeManager:self.bag.themeManager];
        _verifyLoginView = verifyLoginView;
    }

    return _verifyLoginView;
}

#pragma mark - UIViewController life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self configureTableView];
    [self updateVerifyLoginViewWithSuccess:self.bag.loginManager.isLoginValid];

    if (![self.bag.settings isSettingActivated:MCLSettingInitialReportSend]) {
        [self.bag.settings reportSettings];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (self.bag.loginManager.isLoginValid) {
        [self.bag.privateMessagesManager loadConversations];
    }

    if (self.alreadyAppeared && self.bag.loginManager.isLoginValid) {
        [[[MCLMessageResponsesRequest alloc] initWithBag:self.bag] loadResponsesWithCompletion:nil];
    }

    self.alreadyAppeared = YES;

    if ([self.bag.features isFeatureWithNameEnabled:MCLFeatureStoreReview]) {
        [self.bag.storeReviewManager promptForReviewIfAppropriate];
    }
}

#pragma mark - Configuration

- (void)configureToolbarButtons
{
    [self configureResponsesButton];
    [self configurePrivateMessagesButton];
}

- (void)configureResponsesButton
{
    UIImage *responsesImage = [[UIImage imageNamed:@"responsesButton"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIButton *responsesButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 50.0f, 50.0f)];
    [responsesButton setImage:responsesImage forState:UIControlStateNormal];
    [responsesButton addTarget:self action:@selector(responsesButtonPressed) forControlEvents:UIControlEventTouchUpInside];

    self.responsesButtonItem = [[BBBadgeBarButtonItem alloc] initWithCustomUIButton:responsesButton];
    self.responsesButtonItem.badgeOriginX = 0.0f;
    self.responsesButtonItem.badgeOriginY = 8.0f;
    self.responsesButtonItem.shouldHideBadgeAtZero = YES;
    self.responsesButtonItem.badgePadding = 5;
    [self updateResponsesButtonItemBadgeValueFromApplicationIconBadgeNumber];
}

- (void)updateResponsesButtonItemBadgeValueFromApplicationIconBadgeNumber
{
    self.responsesButtonItem.badgeValue = [NSString stringWithFormat:@"%ld", (long)self.bag.application.applicationIconBadgeNumber];
}

- (void)configurePrivateMessagesButton
{
    UIImage *privateMessagesImage = [[UIImage imageNamed:@"privateMessages"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIButton *privateMessagesButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 50.0f, 50.0f)];
    [privateMessagesButton setImage:privateMessagesImage forState:UIControlStateNormal];
    [privateMessagesButton addTarget:self action:@selector(privateMessagesButtonPressed) forControlEvents:UIControlEventTouchUpInside];

    self.privateMessagesButtonItem = [[BBBadgeBarButtonItem alloc] initWithCustomUIButton:privateMessagesButton];
    self.privateMessagesButtonItem.badgeOriginX = 0.0f;
    self.privateMessagesButtonItem.badgeOriginY = 8.0f;
    self.privateMessagesButtonItem.badgeValue = nil;
    self.privateMessagesButtonItem.shouldHideBadgeAtZero = YES;
    self.privateMessagesButtonItem.badgePadding = 5;

    // Hide when FeatureToggle is off
    if (![self.bag.features isFeatureWithNameEnabled:MCLFeaturePrivateMessages]) {
        self.privateMessagesButtonItem.badgeValue = nil;
        [self.privateMessagesButtonItem setEnabled:NO];
        privateMessagesButton.tintColor = [UIColor clearColor];
    }
}

- (void)configureTableView
{
    [self.tableView registerClass:[MCLBoardTableViewCell class] forCellReuseIdentifier:MCLBoardTableViewCellIdentifier];
    UINib *threadCellNib = [UINib nibWithNibName:@"MCLThreadTableViewCell" bundle:nil];
    [self.tableView registerNib:threadCellNib forCellReuseIdentifier:MCLThreadTableViewCellIdentifier];
    [self.tableView setContentInset:UIEdgeInsetsMake(8, 0, 0, 0)];
}

#pragma mark - MCLLoadingViewControllerDelegate

- (NSString *)loadingViewControllerRequestsTitleString:(MCLLoadingViewController *)loadingViewController
{
    return NSLocalizedString(@"Boards", nil);
}

- (UIView *)loadingViewControllerRequestsTitleView:(MCLLoadingViewController *)loadingViewController
{
    return [self noDetailVC] ? [[MCLLogoLabel alloc] initWithBag:self.bag] : nil;
}

- (NSArray<__kindof UIBarButtonItem *> *)loadingViewControllerRequestsToolbarItems:(MCLLoadingViewController *)loadingViewController
{
    UIBarButtonItem *flexibleItem1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil
                                                                                   action:nil];
    UIBarButtonItem *flexibleItem2 = flexibleItem1;
    UIBarButtonItem *verifyLoginViewItem = [[UIBarButtonItem alloc] initWithCustomView:self.verifyLoginView];
    [self.verifyLoginView addTarget:self action:@selector(verifyLoginViewButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    return [NSArray arrayWithObjects:self.responsesButtonItem,
                                     flexibleItem1,
                                     verifyLoginViewItem,
                                     flexibleItem2,
                                     self.privateMessagesButtonItem,
                                     nil];
}

- (void)loadingViewController:(MCLLoadingViewController *)loadingViewController configureNavigationItem:(UINavigationItem *)navigationItem
{
    if ([self.bag.features isFeatureWithNameEnabled:MCLFeatureFullSearch]) {
        navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"searchButton"]
                                                                            style:UIBarButtonItemStylePlain
                                                                           target:self
                                                                           action:@selector(searchButtonPressed:)];
    } else { // Needed to center the title label when FeatureToggle is off :-|
        navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"placeholderBarItem"]
                                                                            style:UIBarButtonItemStylePlain
                                                                           target:nil
                                                                           action:nil];
    }

    navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settingsButton"]
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:self
                                                                        action:@selector(settingsButtonPressed:)];
}

- (void)loadingViewController:(MCLLoadingViewController *)loadingViewController hasRefreshedWithData:(NSArray *)newData forKey:(NSNumber *)key
{
    switch ([key integerValue]) {
        case MCLBoardListSectionBoards:
            self.boards = [newData copy];
            self.bag.keyboardShortcutManager.boards = self.boards;
            if (!self.bag.loginManager.isLoginValid) {
                self.favorites = nil;
            }
            break;

        case MCLBoardListSectionFavorites:
            self.temporarilyDontShowNoFavoritesView = NO;
            self.favorites = [newData mutableCopy];
            break;
    }

    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (BOOL)noDetailVC
{
    BOOL splitNotExist = !self.splitViewController;
    BOOL splitIsCollapsed = self.bag.router.splitViewController.isCollapsed;

    return splitNotExist || splitIsCollapsed;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == MCLBoardListSectionFavorites && [self.favorites count] == 0) {
        return nil;
    }

    UIView *headerView = [[UIView alloc] init];
    headerView.translatesAutoresizingMaskIntoConstraints = YES;

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.font = [UIFont systemFontOfSize:13.0f weight:UIFontWeightRegular];
    titleLabel.textColor = [self.currentTheme tableViewHeaderTextColor];
    titleLabel.text = [self tableView:tableView titleForHeaderInSection:section];

    [headerView addSubview:titleLabel];

    NSDictionary *views = NSDictionaryOfVariableBindings(titleLabel);
    [headerView addConstraints:@"V:|[titleLabel]|" views:views];
    [headerView addConstraints:@"H:|-10-[titleLabel]|" views:views];

    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 38.0f;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([self noDetailVC]) {
        switch (section) {
            case MCLBoardListSectionBoards:
                return NSLocalizedString(@"BOARDS", nil);
                break;
            case MCLBoardListSectionFavorites:
                if ([self.favorites count] > 0) {
                    return NSLocalizedString(@"FAVORITES", nil);
                }
                break;
        }
    }

    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case MCLBoardListSectionBoards:
            return [[self boards] count];
            break;
        case MCLBoardListSectionFavorites:
            if ([self noDetailVC]) {
                NSUInteger favoritesCount = [[self favorites] count];
                NSUInteger minNumberOfCells = self.bag.loginManager.isLoginValid && !self.temporarilyDontShowNoFavoritesView ? 1 : 0;
                return favoritesCount > 0 ? favoritesCount : minNumberOfCells;
            }
            break;
    }

    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case MCLBoardListSectionBoards: return [self boardCellForRowIndexPath:indexPath]; break;
        case MCLBoardListSectionFavorites: return [self favoriteCellForRowIndexPath:indexPath]; break;
    }

    return [[UITableViewCell alloc] init];
}

- (UITableViewCell *)boardCellForRowIndexPath:(NSIndexPath *)indexPath
{
    MCLBoardTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:MCLBoardTableViewCellIdentifier];
    cell.currentTheme = self.bag.themeManager.currentTheme;
    cell.board = self.boards[indexPath.row];

    return cell;
}

- (UITableViewCell *)favoriteCellForRowIndexPath:(NSIndexPath *)indexPath
{
    if ([self.favorites count] == 0) {
        MCLNoDataInfo *info = [MCLNoDataInfo infoForNoFavoritesInfo:self.bag.settings];
        MCLNoDataView *noDataView = [[MCLNoDataView alloc] initWithInfo:info parentViewController:self];
        MCLNoDataTableViewCell *cell = [[MCLNoDataTableViewCell alloc] initWithNoDataView:noDataView];

        return cell;
    }

    MCLThreadTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:MCLThreadTableViewCellIdentifier];
    cell.index = indexPath.row;
    cell.loginManager = self.bag.loginManager;
    cell.currentTheme = self.bag.themeManager.currentTheme;
    cell.thread = self.favorites[indexPath.row];
    cell.threadIsFavoriteImageView.hidden = YES;
    cell.delegate = self;
    cell.leftSwipeSettings.transition = MGSwipeTransitionBorder;
    cell.leftButtons = @[[MGSwipeButton buttonWithTitle:@""
                                                   icon:[UIImage imageNamed:@"favoriteThreadCellSelected"]
                                        backgroundColor:[self.currentTheme tintColor]]];

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
    switch (indexPath.section) {
        case MCLBoardListSectionBoards:
            [self pushToBoardAtIndexPath:indexPath];
            break;
        case MCLBoardListSectionFavorites:
            [self pushToFavoriteAtIndexPath:indexPath];
            break;
    }
}

- (void)pushToBoardAtIndexPath:(NSIndexPath *)indexPath
{
    MCLBoard *selectedBoard = [self.boards objectAtIndex:indexPath.row];
    [self.bag.router pushToThreadListFromBoard:selectedBoard];
}

- (void)pushToFavoriteAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.favorites || [self.favorites count] == 0) {
        return;
    }

    MCLThread *thread = [self.favorites objectAtIndex:indexPath.row];
    thread.board = [MCLBoard boardWithId:thread.boardId];
    MCLMessageListViewController *messageListVC = [self.bag.router pushToThread:thread];
    messageListVC.delegate = self;
}

#pragma mark - MGSwipeTableCellDelegate

- (BOOL)swipeTableCell:(nonnull MGSwipeTableCell*)cell tappedButtonAtIndex:(NSInteger)index direction:(MGSwipeDirection)direction fromExpansion:(BOOL)fromExpansion
{
    MCLThreadTableViewCell *favoriteCell = (MCLThreadTableViewCell *)cell;
    MCLThread *thread = self.favorites[favoriteCell.index];

    [favoriteCell hideSwipeAnimated:YES];

    MCLFavoriteThreadToggleRequest *favoriteThreadToggleRequest = [[MCLFavoriteThreadToggleRequest alloc] initWithClient:self.bag.httpClient
                                                                                                                  thread:thread];
    favoriteThreadToggleRequest.forceRemove = YES;
    [favoriteThreadToggleRequest loadWithCompletionHandler:^(NSError *error, NSArray *result) {
        if (error) {
            [self presentError:error];
            return;
        }

        self.temporarilyDontShowNoFavoritesView = YES;
        [self.favorites removeObjectAtIndex:favoriteCell.index];
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:favoriteCell.index inSection:MCLBoardListSectionFavorites]]
                              withRowAnimation:UITableViewRowAnimationLeft];
        self.temporarilyDontShowNoFavoritesView = NO;
        [self.tableView reloadData];
        [self.bag.soundEffectPlayer playRemoveThreadFromFavoritesSound];

        [[NSNotificationCenter defaultCenter] postNotificationName:MCLFavoritedChangedNotification
                                                            object:self
                                                          userInfo:nil];
    }];

    return NO;
}

#pragma mark - MCLMessageListDelegate

- (void)messageListViewController:(MCLMessageListViewController *)inController didFinishLoadingThread:(MCLThread *)inThread
{ }

- (void)messageListViewController:(MCLMessageListViewController *)inController didReadMessageOnThread:(MCLThread *)inThread
{
    NSIndexPath *selectedIndexPath = self.tableView.indexPathForSelectedRow;
    if (selectedIndexPath) {
        MCLThreadTableViewCell *selectedCell = [self.tableView cellForRowAtIndexPath:selectedIndexPath];
        [selectedCell updateBadgeWithThread:inThread andTheme:self.currentTheme];
    }
}

#pragma mark - Actions

- (void)searchButtonPressed:(UIBarButtonItem *)sender
{
    [self.bag.router pushToSearchWithBoards:self.boards];
}

- (void)settingsButtonPressed:(UIBarButtonItem *)sender
{
    [self.bag.router modalToSettings];
}

- (void)responsesButtonPressed
{
    [self.bag.router pushToResponses];
}

- (void)verifyLoginViewButtonPressed:(id)sender
{
    [self.bag.router pushToDrafts];
}

- (void)privateMessagesButtonPressed
{
    [self.bag.router pushToPrivateMessages];
}

#pragma mark - Notifications

- (void)loginStateDidChanged:(NSNotification *)notification
{
    BOOL success = [[notification.userInfo objectForKey:MCLLoginStateKey] boolValue];
    [self updateVerifyLoginViewWithSuccess:success];
    self.temporarilyDontShowNoFavoritesView = YES;
}

- (void)themeChanged:(NSNotification *)notification
{
    self.currentTheme = self.bag.themeManager.currentTheme;
    [self.tableView reloadData];
}

- (void)foundUnreadResponses:(NSNotification *)notification
{
    self.responsesButtonItem.badgeValue = [[[notification userInfo] objectForKey:@"numberOfUnreadResponses"] stringValue];
}

- (void)draftsChanged:(NSNotification *)notification
{
    [self updateVerifyLoginViewWithSuccess:self.bag.loginManager.isLoginValid];
}

- (void)privateMessagesChanged:(NSNotification *)notification
{
    self.privateMessagesButtonItem.badgeValue = [[[notification userInfo] objectForKey:@"numberOfUnreadMessages"] stringValue];
}

#pragma mark - Public

- (void)updateVerifyLoginViewWithSuccess:(BOOL)success
{
    if (success) {
        [self.verifyLoginView loginStatusWithUsername:self.bag.loginManager.username];
        [[[MCLMessageResponsesRequest alloc] initWithBag:self.bag] loadResponsesWithCompletion:nil];
        [self.responsesButtonItem setEnabled:YES];
        [self.privateMessagesButtonItem setEnabled:YES];
        [self updateResponsesButtonItemBadgeValueFromApplicationIconBadgeNumber];

        if ([self.bag.features isFeatureWithNameEnabled:MCLFeatureDrafts]) {
            [self.verifyLoginView setNumberOfDrafts:self.bag.draftManager.count withDelay:2];
        }
    } else {
        [self.verifyLoginView loginStatusNoLogin];
        self.responsesButtonItem.badgeValue = 0;
        [self.responsesButtonItem setEnabled:NO];
        [self.privateMessagesButtonItem setEnabled:NO];
    }
}

@end

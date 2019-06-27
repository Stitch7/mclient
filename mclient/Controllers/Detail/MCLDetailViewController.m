//
//  MCLDetailViewController.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLDetailViewController.h"

#import "MGSwipeTableCell.h"

#import "MCLDependencyBag.h"
#import "UIView+addConstraints.h"
#import "UIViewController+Additions.h"
#import "MCLRouter+mainNavigation.h"
#import "MCLLoginManager.h"
#import "MCLSoundEffectPlayer.h"
#import "MCLBoard.h"
#import "MCLThread.h"
#import "MCLFavoritesRequest.h"
#import "MCLFavoriteThreadToggleRequest.h"
#import "MCLTheme.h"
#import "MCLThemeManager.h"
#import "MCLSplitViewController.h"
#import "MCLLoadingViewController.h"
#import "MCLLogoLabel.h"
#import "MCLThreadTableViewCell.h"
#import "MCLThreadListTableViewController.h"
#import "MCLNoDataViewPresentingViewController.h"
#import "MCLNoDataInfo.h"
#import "MCLNoDataView.h"


@interface MCLDetailViewController () <UITableViewDataSource, UITableViewDelegate, MGSwipeTableCellDelegate, MCLNoDataViewPresentingViewController>

@property (strong, nonatomic) id <MCLTheme> currentTheme;
@property (strong, nonatomic) MCLNoDataView *noDataView;

@end

@implementation MCLDetailViewController

#pragma mark - Initializers

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag
{
    self = [super initWithNibName:@"MCLDetailViewController" bundle:nil];
    if (!self) return nil;

    self.bag = bag;
    [self configure];

    return self;
}

#pragma mark - UIViewController life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self configureNotifications];
    [self configureView];
    [self configureTableView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // Clear previous selection
    NSIndexPath *selectedIndexPath = self.tableView.indexPathForSelectedRow;
    if (selectedIndexPath) {
        [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:animated];
    }
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    CGFloat margin = self.view.frame.size.width / 10;
    self.tableViewLeadingConstraint.constant = margin;
    self.tableViewTrailingConstraint.constant = margin;
}

#pragma mark - Configuration

- (void)configure
{
    self.currentTheme = self.bag.themeManager.currentTheme;
    self.favorites = [[NSMutableArray alloc] init];
}

- (void)configureNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loginStateDidChanged:)
                                                 name:MCLLoginStateDidChangeNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(themeChanged:)
                                                 name:MCLThemeChangedNotification
                                               object:nil];
}

- (void)configureView
{
    self.view.backgroundColor = [self.currentTheme tableViewBackgroundColor];
}

- (void)configureTableView
{
    UINib *threadCellNib = [UINib nibWithNibName:@"MCLThreadTableViewCell" bundle:nil];
    [self.tableView registerNib:threadCellNib forCellReuseIdentifier:MCLThreadTableViewCellIdentifier];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    [self configureNoDataView];
}

- (void)configureNoDataView
{
    MCLNoDataInfo *noDataInfo;
    if (self.bag.loginManager.isLoginValid) {
        noDataInfo = [MCLNoDataInfo infoForNoFavoritesInfo:self.bag.settings];
    } else {
        noDataInfo = [MCLNoDataInfo infoForLoginToSeeFavoritesInfo];
    }
    self.noDataView = [[MCLNoDataView alloc] initWithInfo:noDataInfo parentViewController:self];
}

- (void)menuButtonPressed
{
    self.bag.router.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
}

#pragma mark - MCLLoadingContentViewControllerDelegate

- (NSString *)loadingViewControllerRequestsTitleString:(MCLLoadingViewController *)loadingViewController
{
    self.title = NSLocalizedString(@"Favs", nil);
    return self.title;
}

- (UIView *)loadingViewControllerRequestsTitleView:(MCLLoadingViewController *)loadingViewController
{
    return [[MCLLogoLabel alloc] initWithBag:self.bag];
}

- (void)loadingViewController:(MCLLoadingViewController *)loadingViewController hasRefreshedWithData:(NSArray *)newData forKey:(NSNumber *)key
{
    self.favorites = [newData mutableCopy];
    [self.tableView reloadData];
}

#pragma mark - UITableView Datasource

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if ([self.favorites count] == 0) {
        return nil;
    }

    UIView *headerView = [[UIView alloc] init];
    headerView.translatesAutoresizingMaskIntoConstraints = YES;

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.font = [UIFont systemFontOfSize:13.0f weight:UIFontWeightRegular];
    titleLabel.textColor = [self.currentTheme tableViewHeaderTextColor];
    titleLabel.text = NSLocalizedString(@"FAVORITES", nil);

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

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    MCLThreadTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:MCLThreadTableViewCellIdentifier];
    cell.index = indexPath.row;
    cell.loginManager = self.bag.loginManager;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
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

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger favoritesCount = [self.favorites count];

    if (favoritesCount == 0) {
        [self.noDataView updateVisibility];
        self.tableView.backgroundView = self.noDataView;
    } else {
        self.tableView.backgroundView = nil;
    }

    return favoritesCount;
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
    MCLThread *thread = [self.favorites objectAtIndex:indexPath.row];
    thread.board = [MCLBoard boardWithId:thread.boardId name:@""];
    [self.bag.router pushToThread:thread];
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
        }

        [self.favorites removeObjectAtIndex:favoriteCell.index];
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:favoriteCell.index inSection:0]]
                              withRowAnimation:UITableViewRowAnimationLeft];
        [self.bag.soundEffectPlayer playRemoveThreadFromFavoritesSound];

        [[NSNotificationCenter defaultCenter] postNotificationName:MCLFavoritedChangedNotification
                                                            object:self
                                                          userInfo:nil];
    }];

    return NO;
}

#pragma mark - Notifications

- (void)loginStateDidChanged:(NSNotification *)notification
{
    [self configureNoDataView];
}

- (void)themeChanged:(NSNotification *)notification
{
    self.currentTheme = self.bag.themeManager.currentTheme;
    [self configureView];
    [self.tableView reloadData];
}

@end

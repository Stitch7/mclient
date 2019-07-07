//
//  MCLUserSearchViewController.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLUserSearchViewController.h"

#import "UIView+addConstraints.h"
#import "UIViewController+Additions.h"
#import "MCLUserSearchDelegate.h"
#import "MCLDependencyBag.h"
#import "MCLThemeManager.h"
#import "MCLTheme.h"
#import "MCLUser.h"
#import "MCLUserSearchFormView.h"
#import "MCLUserSearchFormViewDelegate.h"
#import "MCLUserSearchRequest.h"
#import "MCLTextField.h"
#import "MCLPacmanLoadingView.h"
#import "MCLLoadingTableViewCell.h"
#import "MCLNoDataInfo.h"
#import "MCLNoDataView.h"
#import "MCLNoDataTableViewCell.h"

@interface MCLUserSearchViewController () <MCLUserSearchFormViewDelegate>

@property (strong, nonatomic) id <MCLDependencyBag> bag;
@property (strong, nonatomic) NSArray<MCLUser *> *users;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) MCLUserSearchFormView *searchFormView;
@property (assign, nonatomic) BOOL isLoading;

@end

@implementation MCLUserSearchViewController

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
    self.isLoading = NO;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(themeChanged:)
                                                 name:MCLThemeChangedNotification
                                               object:nil];

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UIViewController life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self themeChanged:nil];
    [self configureNavigationBar];
    [self configureTableView];
    [self configureSearchFormView];

    [self.searchFormView.searchTextField becomeFirstResponder];
}

#pragma mark - Configuration

- (void)configureNavigationBar
{
//    self.title = NSLocalizedString(@"search_title", nil);
    [self.navigationController setToolbarHidden:YES animated:NO];
}

- (void)configureTableView
{
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UserSearchCell"];
}

- (void)configureSearchFormView
{
    self.searchFormView = [[MCLUserSearchFormView alloc] initWithBag:self.bag];
    self.searchFormView.delegate = self;
    self.tableView.tableHeaderView = self.searchFormView;

    [self.searchFormView setNeedsLayout];
    [self.searchFormView layoutIfNeeded];
    CGFloat height = [self.searchFormView.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;

    // Update the header's frame and set it again
    CGRect headerFrame = self.searchFormView.frame;
    headerFrame.size.height = height + 50;
    self.searchFormView.frame = headerFrame;
    self.tableView.tableHeaderView = self.searchFormView;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!self.users && !self.isLoading) {
        return 0;
    }

    if (self.isLoading || [self.users count] == 0) {
        return 1;
    }

    return [self.users count];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] init];
    headerView.translatesAutoresizingMaskIntoConstraints = YES;

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.font = [UIFont systemFontOfSize:13.0f weight:UIFontWeightRegular];
    titleLabel.textColor = [self.bag.themeManager.currentTheme tableViewHeaderTextColor];
    titleLabel.text = [self tableView:tableView titleForHeaderInSection:section];

    [headerView addSubview:titleLabel];

    NSDictionary *views = NSDictionaryOfVariableBindings(titleLabel);
    [headerView addConstraints:@"V:|[titleLabel]|" views:views];
    [headerView addConstraints:@"H:|-15-[titleLabel]|" views:views];

    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 38.0f;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.users || self.isLoading ? NSLocalizedString(@"search_results_header", nil) : nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isLoading) {
        MCLPacmanLoadingView *loadingView = [[MCLPacmanLoadingView alloc] initWithTheme:self.bag.themeManager.currentTheme];
        MCLLoadingTableViewCell *cell = [[MCLLoadingTableViewCell alloc] initWithLoadingView:loadingView];

        return cell;
    }

    if (self.users && [self.users count] == 0) {
        MCLNoDataInfo *info = [MCLNoDataInfo infoForNoSearchResultsInfo];
        MCLNoDataView *noDataView = [[MCLNoDataView alloc] initWithInfo:info];
        MCLNoDataTableViewCell *cell = [[MCLNoDataTableViewCell alloc] initWithNoDataView:noDataView];

        return cell;
    }

    id <MCLTheme> currenTheme = self.bag.themeManager.currentTheme;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserSearchCell" forIndexPath:indexPath];

    MCLUser *user = self.users[indexPath.row];

    cell.textLabel.text = user.username;
    cell.textLabel.textColor = [currenTheme textColor];

    UIView *backgroundView = [[UIView alloc] initWithFrame:cell.frame];
    backgroundView.backgroundColor = [currenTheme tableViewCellSelectedBackgroundColor];
    cell.selectedBackgroundView = backgroundView;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MCLUser *selectedUser = self.users[indexPath.row];
    [self.delegate userSearchViewController:self didPickUser:selectedUser];
}

#pragma mark - MCLUserSearchFormViewDelegate

- (void)userSearchFormView:(MCLUserSearchFormView *)userSearchFormView firedWithError:(NSError *)error
{
    [self presentError:error];
}

- (void)userSearchFormView:(MCLUserSearchFormView *)userSearchFormView firedWithSearchText:(NSString *)searchText
{
    if (self.isLoading) {
        return;
    }

    self.isLoading = YES;
    [self.tableView reloadData];
    MCLUserSearchRequest *searchRequest = [[MCLUserSearchRequest alloc] initWithClient:self.bag.httpClient searchText:searchText];
    [searchRequest loadWithCompletionHandler:^(NSError *error, NSArray *users) {
        if (error) {
            self.users = nil;
            [self presentError:error];
        } else {
            self.users = users;
        }

        self.isLoading = NO;
        [self.tableView reloadData];
    }];
}

#pragma mark - Notifications

- (void)themeChanged:(NSNotification *)notification
{
    self.tableView.backgroundColor = [self.bag.themeManager.currentTheme tableViewBackgroundColor];
    self.tableView.separatorColor = [self.bag.themeManager.currentTheme tableViewSeparatorColor];

    if (notification) {
        [self.tableView reloadData];
    }
}

@end

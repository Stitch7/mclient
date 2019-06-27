//
//  MCLSearchTableViewController.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLSearchTableViewController.h"

#import "UIView+addConstraints.h"
#import "UIViewController+Additions.h"
#import "MCLDependencyBag.h"
#import "MCLLoginManager.h"
#import "MCLThemeManager.h"
#import "MCLRouter+mainNavigation.h"
#import "MCLBoard.h"
#import "MCLMessage.h"
#import "MCLSearchQuery.h"
#import "MCLSearchRequest.h"
#import "MCLSearchFormView.h"
#import "MCLSearchFormViewDelegate.h"
#import "MCLMessageListFrameStyleTableViewCell.h"
#import "MCLPacmanLoadingView.h"
#import "MCLLoadingTableViewCell.h"
#import "MCLNoDataInfo.h"
#import "MCLNoDataView.h"
#import "MCLNoDataTableViewCell.h"


@interface MCLSearchTableViewController () <MCLSearchFormViewDelegate>

@property (strong, nonatomic) id <MCLDependencyBag> bag;
@property (strong, nonatomic) NSArray<MCLBoard *> *boards;
@property (strong, nonatomic) NSArray<MCLMessage *> *messages;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) MCLSearchFormView *searchFormView;
@property (assign, nonatomic) BOOL isLoading;

@end

@implementation MCLSearchTableViewController

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

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag boards:(NSArray<MCLBoard *>*)boards
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (!self) return nil;

    self.bag = bag;
    self.boards = boards;
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
}

#pragma mark - Configuration

- (void)configureNavigationBar
{
    self.title = NSLocalizedString(@"search_title", nil);
    [self.navigationController setToolbarHidden:YES animated:NO];
}

- (void)configureTableView
{
    UINib *messageCellNib = [UINib nibWithNibName:@"MCLMessageListFrameStyleTableViewCell" bundle: nil];
    [self.tableView registerNib: messageCellNib forCellReuseIdentifier:MCLMessageListFrameStyleTableViewCellIdentifier];
}

- (void)configureSearchFormView
{
    self.searchFormView = [[MCLSearchFormView alloc] initWithBag:self.bag boards:self.boards];
    self.searchFormView.delegate = self;
    self.tableView.tableHeaderView = self.searchFormView;

    [self.searchFormView setNeedsLayout];
    [self.searchFormView layoutIfNeeded];
    CGFloat height = [self.searchFormView.mainStackView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;

    // Update the header's frame and set it again
    CGRect headerFrame = self.searchFormView.frame;
    headerFrame.size.height = height + 50;
    self.searchFormView.frame = headerFrame;
    self.tableView.tableHeaderView = self.searchFormView;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!self.messages && !self.isLoading) {
        return 0;
    }

    if (self.isLoading || [self.messages count] == 0) {
        return 1;
    }

    return [self.messages count];
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
    return self.messages || self.isLoading ? NSLocalizedString(@"search_results_header", nil) : nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isLoading) {
        MCLPacmanLoadingView *loadingView = [[MCLPacmanLoadingView alloc] initWithTheme:self.bag.themeManager.currentTheme];
        MCLLoadingTableViewCell *cell = [[MCLLoadingTableViewCell alloc] initWithLoadingView:loadingView];

        return cell;
    }

    if (self.messages && [self.messages count] == 0) {
        MCLNoDataInfo *info = [MCLNoDataInfo infoForNoSearchResultsInfo];
        MCLNoDataView *noDataView = [[MCLNoDataView alloc] initWithInfo:info];
        MCLNoDataTableViewCell *cell = [[MCLNoDataTableViewCell alloc] initWithNoDataView:noDataView];

        return cell;
    }

    id <MCLTheme> currenTheme = self.bag.themeManager.currentTheme;
    MCLMessageListFrameStyleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MCLMessageListFrameStyleTableViewCellIdentifier forIndexPath:indexPath];

    MCLMessage *message = self.messages[indexPath.row];

    cell.message = message;

    [cell setBoardId:message.boardId];
    [cell setMessageId:message.messageId];

    UIView *backgroundView = [[UIView alloc] initWithFrame:cell.frame];
    backgroundView.backgroundColor = [currenTheme tableViewCellSelectedBackgroundColor];
    cell.selectedBackgroundView = backgroundView;

    cell.messageIndentionImageView.hidden = YES;
    cell.indentionConstraint.constant = 0;

    cell.messageSubjectLabel.text = message.subject;
    cell.messageSubjectLabel.textColor = [currenTheme textColor];

    cell.messageUsernameLabel.text = message.username;
    if ([message.username isEqualToString:self.bag.loginManager.username]) {
        cell.messageUsernameLabel.textColor = [currenTheme ownUsernameTextColor];
    } else if (message.isMod) {
        cell.messageUsernameLabel.textColor = [currenTheme modTextColor];
    } else {
        cell.messageUsernameLabel.textColor = [currenTheme usernameTextColor];
    }

    cell.messageDateLabel.text = [self.dateFormatter stringFromDate:message.date];
    cell.messageDateLabel.textColor = [currenTheme detailTextColor];

    [cell markRead];

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
    MCLMessage *message = self.messages[indexPath.row];
    [self.bag.router pushToMessage:message];
}

#pragma mark - MCLSearchFormViewDelegate

- (NSArray<MCLBoard*>*)searchFormViewRequestsBoardList:(MCLSearchFormView *)searchFormView
{
    return self.boards;
}

- (void)searchFormView:(MCLSearchFormView *)searchFormView firedWithError:(NSError *)error
{
    [self presentError:error];
}

- (void)searchFormView:(MCLSearchFormView *)searchFormView firedWithSearchQuery:(MCLSearchQuery *)searchQuery
{
    if (self.isLoading) {
        return;
    }

    self.isLoading = YES;
    self.searchFormView.searchButton.enabled = NO;
    [self.tableView reloadData];
    MCLSearchRequest *searchRequest = [[MCLSearchRequest alloc] initWithClient:self.bag.httpClient searchQuery:searchQuery];
    [searchRequest loadWithCompletionHandler:^(NSError *error, NSArray *messages) {
        if (error) {
            self.messages = nil;
            [self presentError:error];
        } else {
            self.messages = messages;
        }

        self.isLoading = NO;
        self.searchFormView.searchButton.enabled = YES;
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

//
//  MCLThreadListTableViewController.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLThreadListTableViewController.h"

#import "UISearchBar+getSearchField.h"
#import "UIViewController+Additions.h"
#import "MCLDependencyBag.h"
#import "MCLFeatures.h"
#import "MCLRouter+mainNavigation.h"
#import "MCLSearchThreadsRequest.h"
#import "MCLFavoriteThreadToggleRequest.h"
#import "MCLKillfileThreadToggleRequest.h"
#import "MCLMarkThreadAsReadRequest.h"
#import "MCLLogin.h"
#import "MCLThemeManager.h"
#import "MCLMessageListViewController.h"
#import "MCLThreadTableViewCell.h"
#import "MCLBoard.h"
#import "MCLThread.h"
#import "MCLMessage.h"
#import "MCLBadgeView.h"
#import "MCLSplitViewController.h"
#import "MCLLoadingViewController.h"

NSString * const MCLFavoritedChangedNotification = @"MCLFavoritedChangedNotification";

@interface MCLThreadListTableViewController ()

@property (strong, nonatomic) MCLMessageListViewController *detailViewController;
@property (strong, nonatomic) id <MCLTheme> currentTheme;
@property (strong, nonatomic) UISearchController *searchController;
@property (strong, nonatomic) NSTimer *searchTimer;
@property (strong, nonatomic) NSMutableArray *searchResults;

@end

@implementation MCLThreadListTableViewController

#pragma mark - Initializers

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (!self) return nil;

    self.bag = bag;
    self.currentTheme = self.bag.themeManager.currentTheme;

    [self configureNotifications];

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

    [self configureTableView];

    self.detailViewController.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.currentTheme = self.bag.themeManager.currentTheme;
}

#pragma mark - Configuration

- (void)configureNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(themeChanged:)
                                                 name:MCLThemeChangedNotification
                                               object:nil];
}

- (void)configureTableView
{
    UINib *threadCellNib = [UINib nibWithNibName: @"MCLThreadTableViewCell" bundle: nil];
    [self.tableView registerNib: threadCellNib forCellReuseIdentifier: MCLThreadTableViewCellIdentifier];

    [UIView animateWithDuration:0 animations:^{
        [self.tableView reloadData];
    } completion:^(BOOL finished) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                              atScrollPosition:UITableViewScrollPositionTop
                                      animated:NO];
    }];

    [self configureSearchResultsController];
}

- (void)configureSearchResultsController
{
    self.definesPresentationContext = YES;
    self.searchController = [[UISearchController alloc] initWithSearchResultsController: nil];
    self.tableView.tableHeaderView = self.searchController.searchBar;
    [self.searchController loadViewIfNeeded];
    self.searchController.delegate = self;
    self.searchController.searchResultsUpdater = self;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.searchBar.placeholder = NSLocalizedString(@"Search", nil);
    self.searchController.searchBar.searchBarStyle = UISearchBarStyleProminent;

    // TODO: Why does UIAppearance not work here?
    UITextField *searchField = [self.searchController.searchBar getSearchField];
    [searchField setBackgroundColor:[self.currentTheme searchFieldBackgroundColor]];
    [searchField setTextColor:[self.currentTheme searchFieldTextColor]];
}

#pragma mark - MCLLoadingContentViewControllerDelegate

- (NSString *)loadingViewControllerRequestsTitleString:(MCLLoadingViewController *)loadingViewController
{
    return self.board.name;
}

- (void)loadingViewController:(MCLLoadingViewController *)loadingViewController configureNavigationItem:(UINavigationItem *)navigationItem
{
    if (self.bag.login.valid) {
        navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                                                                                          target:self
                                                                                          action:@selector(composeThreadButtonPressed:)];
    }
}

- (void)loadingViewController:(MCLLoadingViewController *)loadingViewController hasRefreshedWithData:(NSArray *)newData forKey:(NSNumber *)key
{
    self.threads = [newData copy];
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self isSearching] ? [self.searchResults count] : [self.threads count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MCLThreadTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:MCLThreadTableViewCellIdentifier];
    cell.index = indexPath.row;
    cell.login = self.bag.login;
    cell.currentTheme = self.bag.themeManager.currentTheme;
    MCLThread *thread = [self isSearching] ? self.searchResults[indexPath.row] : self.threads[indexPath.row];
    cell.thread = thread;

    cell.delegate = self;
    cell.leftSwipeSettings.transition = MGSwipeTransitionBorder;

    UIImage *favoriteImage = thread.isFavorite ? [UIImage imageNamed:@"favoriteThreadCellSelected"] : [UIImage imageNamed:@"favoriteThreadCell"];
    UIImage *hideThreadImage = [UIImage imageNamed:@"hideThreadCell"];

    NSMutableArray *leftButtons = [[NSMutableArray alloc] init];
    [leftButtons addObject:[MGSwipeButton buttonWithTitle:@""
                                                     icon:favoriteImage
                                          backgroundColor:[self.currentTheme tintColor]]];
    if ([self.bag.features isFeatureWithNameEnabled:MCLFeatureKillFileThreads]) {
        [leftButtons addObject:[MGSwipeButton buttonWithTitle:@""
                                                         icon:hideThreadImage
                                              backgroundColor:[self.currentTheme modTextColor]]];
    }

    if (self.bag.login.valid) {
        cell.leftButtons = leftButtons;
    }

    // After feature toggle removal
//    cell.leftButtons = @[[MGSwipeButton buttonWithTitle:@"" icon:favoriteImage backgroundColor:[self.currentTheme tintColor]],
//                         [MGSwipeButton buttonWithTitle:@"" icon:hideThreadImage backgroundColor:[self.currentTheme modTextColor]]];

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    MCLThread *thread = [self isSearching] ? self.searchResults[indexPath.row] : self.threads[indexPath.row];
    BOOL hasUnreadMessages = [thread.messagesRead compare:thread.messagesCount] == NSOrderedAscending;

    return hasUnreadMessages;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // this method must be at least implemented too or nothing will work
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
    MCLThread *thread = [self isSearching] ? self.searchResults[indexPath.row] : self.threads[indexPath.row];
    MCLThreadTableViewCell *cell = (MCLThreadTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell markRead];

    thread.board = self.board;
    thread.tempRead = YES;

    MCLMessageListViewController *messageListVC = [self.bag.router pushToThread:thread];
    messageListVC.delegate = self;
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    void (^markThreadAsRead)(UITableViewRowAction *action, NSIndexPath *indexPath) = ^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        MCLThread *selectedThread = [self isSearching] ? self.searchResults[indexPath.row] : self.threads[indexPath.row];

        [[[MCLMarkThreadAsReadRequest alloc] initWithClient:self.bag.httpClient thread:selectedThread] loadWithCompletionHandler:^(NSError *error, NSArray *data) {
            if (error) { // TODO: Display error to user
                NSLog(@"%@ - %@", error, data);
            } else {
                MCLThreadTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                [cell markRead];
                selectedThread.read = YES;
                selectedThread.lastMessageRead = YES;
                selectedThread.messagesRead = selectedThread.messagesCount;
                [cell updateBadgeWithThread:selectedThread andTheme:self.currentTheme];
            }

            self.tableView.editing = NO;
        }];
    };

    UITableViewRowAction *button = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault
                                                                      title:NSLocalizedString(@"Mark as read", nil)
                                                                    handler:markThreadAsRead];
    button.backgroundColor = [self.currentTheme tintColor];

    return @[button];
}

#pragma mark - MGSwipeTableCellDelegate

- (BOOL)swipeTableCell:(nonnull MGSwipeTableCell*)cell tappedButtonAtIndex:(NSInteger)index direction:(MGSwipeDirection)direction fromExpansion:(BOOL)fromExpansion
{
    MCLThreadTableViewCell *threadCell = (MCLThreadTableViewCell *)cell;
    switch (index) {
        case 0: [self addThreadToFavorites:threadCell]; break;
        case 1: [self addThreadToKillfile:threadCell]; break;
    }

    return NO;
}

- (void)addThreadToFavorites:(MCLThreadTableViewCell *)threadCell
{
    MCLThread *thread = [self isSearching] ? self.searchResults[threadCell.index] : self.threads[threadCell.index];
    thread.favorite = !thread.isFavorite;
    [threadCell setFavorite:thread.isFavorite];
    [threadCell hideSwipeAnimated:YES];

    [[[MCLFavoriteThreadToggleRequest alloc] initWithClient:self.bag.httpClient thread:thread] loadWithCompletionHandler:^(NSError *error, NSArray *result) {
        if (error) {
            thread.favorite = !thread.isFavorite;
            [threadCell setFavorite:thread.isFavorite];
            [self presentError:error];
            return;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:MCLFavoritedChangedNotification
                                                            object:self
                                                          userInfo:nil];
    }];
}

- (void)addThreadToKillfile:(MCLThreadTableViewCell *)threadCell
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Hide thread?", nil)
                                                                             message:NSLocalizedString(@"Move this thread to your Killfile?", nil)
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    void (^cancelHandler)(UIAlertAction *action) = ^(UIAlertAction * _Nonnull action) {
        [threadCell hideSwipeAnimated:YES];
    };
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                           style:UIAlertActionStyleCancel
                                                         handler:cancelHandler];
    [alertController addAction:cancelAction];

    void (^addToKillfileHandler)(UIAlertAction *action) = ^(UIAlertAction* _Nonnull action) {
        [self.threads removeObjectAtIndex:threadCell.index];
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:threadCell.index inSection:0]]
                              withRowAnimation:UITableViewRowAnimationLeft];
        [threadCell hideSwipeAnimated:YES];
        MCLThread *thread = [self isSearching] ? self.searchResults[threadCell.index] : self.threads[threadCell.index];
        MCLKillfileThreadToggleRequest *request = [[MCLKillfileThreadToggleRequest alloc] initWithClient:self.bag.httpClient
                                                                                                  thread:thread];
        [request loadWithCompletionHandler:^(NSError *error, NSArray *data) {

        }];
    };
    UIAlertAction *addToKillfileAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Hide thread", nil)
                                                            style:UIAlertActionStyleDestructive
                                                          handler:addToKillfileHandler];
    [alertController addAction:addToKillfileAction];
    
    
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - MCLComposeMessageViewControllerDelegate

- (void)message:(MCLMessage *)message sentWithType:(NSUInteger)type
{
    [self.loadingViewController refresh];

    NSString *alertMessage = [NSString stringWithFormat:NSLocalizedString(@"Thank you for your contribution \"%@\"", nil), message.subject];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Confirmation", nil)
                                                                   message:alertMessage
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];;

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - MCLMessageListDelegate

- (void)messageListViewController:(MCLMessageListViewController *)inController didReadMessageOnThread:(MCLThread *)inThread
{
    NSIndexPath *selectedIndexPath = self.tableView.indexPathForSelectedRow;
    if (selectedIndexPath) {
        MCLThreadTableViewCell *selectedCell = [self.tableView cellForRowAtIndexPath:selectedIndexPath];
        [selectedCell updateBadgeWithThread:inThread andTheme:self.currentTheme];
        [self.tableView reloadRowsAtIndexPaths:@[selectedIndexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
}

#pragma mark - UISearchResultsUpdating

- (BOOL)isSearching
{
    if (self.searchController) {
        return self.searchController.isActive;
    }

    return NO;
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    // Cancel button pressed
    if (![self isSearching]) {
        [self.tableView reloadData];
    }

    NSString *searchString = _searchController.searchBar.text;
    if (searchString == nil || searchString.length == 0) {
        self.searchResults = [NSMutableArray array];
        [self.tableView reloadData];
        return;
    }

    if (self.searchTimer) {
        [self.searchTimer invalidate];
        self.searchTimer = nil;
    }

    self.searchTimer = [NSTimer scheduledTimerWithTimeInterval:0.9
                                                        target:self
                                                      selector:@selector(searchTimerPopped:)
                                                      userInfo:searchString
                                                       repeats:NO];
}

- (void)searchTimerPopped:(NSTimer *)searchTimer
{
    [self doSearch:searchTimer.userInfo];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self doSearch:searchBar.text];
}

- (void)doSearch:(NSString *)searchString
{
    MCLSearchThreadsRequest *request = [[MCLSearchThreadsRequest alloc] initWithClient:self.bag.httpClient
                                                                                 board:self.board
                                                                             andPhrase:searchString];
    [request loadWithCompletionHandler:^(NSError *error, NSArray *data) {
        if (error) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                           message:[error localizedDescription]
                                                                    preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action) {
                                                                 [alert dismissViewControllerAnimated:YES completion:nil];
                                                             }];
            [alert addAction:okAction];

            [self presentViewController:alert animated:YES completion:nil];
        } else {
            self.searchResults = [NSMutableArray array];
            for (NSDictionary *json in [data firstObject]) {
                [self.searchResults addObject:[MCLThread threadFromJSON:json]];
            }

            [self.tableView reloadData];
        }
    }];
}

#pragma mark - Actions

- (void)composeThreadButtonPressed:(UIBarButtonItem *)sender
{
    MCLComposeMessageViewController *composeMessageVC = [self.bag.router modalToComposeThreadToBoard:self.board];
    composeMessageVC.delegate = self;
}

#pragma mark - Notifications

- (void)themeChanged:(NSNotification *)notification
{
    self.currentTheme = self.bag.themeManager.currentTheme;
    [self configureSearchResultsController];
    [self.tableView setSeparatorColor:[self.currentTheme tableViewSeparatorColor]];
    [self.tableView reloadData];
}

@end

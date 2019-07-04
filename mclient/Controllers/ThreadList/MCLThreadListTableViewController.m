//
//  MCLThreadListTableViewController.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
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
#import "MCLLoginManager.h"
#import "MCLThemeManager.h"
#import "MCLDraftManager.h"
#import "MCLKeyboardShortcutManager.h"
#import "MCLSoundEffectPlayer.h"
#import "MCLSplitViewController.h"
#import "MCLMessageListViewController.h"
#import "MCLThreadTableViewCell.h"
#import "MCLBoard.h"
#import "MCLThread.h"
#import "MCLMessage.h"
#import "MCLDraft.h"
#import "MCLBadgeView.h"
#import "MCLSplitViewController.h"
#import "MCLLoadingViewController.h"
#import "MCLDraftBarView.h"


NSString * const MCLFavoritedChangedNotification = @"MCLFavoritedChangedNotification";

@interface MCLThreadListTableViewController ()

@property (strong, nonatomic) id <MCLTheme> currentTheme;
@property (strong, nonatomic) UISearchController *searchController;
@property (strong, nonatomic) NSTimer *searchTimer;
@property (strong, nonatomic) NSMutableArray *searchResults;
@property (assign, nonatomic) BOOL isLoadingThread;

@end

@implementation MCLThreadListTableViewController

#pragma mark - Initializers

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (!self) return nil;

    self.bag = bag;
    self.currentTheme = self.bag.themeManager.currentTheme;
    self.isLoadingThread = NO;

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

    self.bag.keyboardShortcutManager.threadsKeyboardShortcutsDelegate = self;

    [self configureTableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.currentTheme = self.bag.themeManager.currentTheme;
    [self.loadingViewController updateToolbar];
//    [self configureDraftBar];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [self.tableView setEditing:NO animated:NO];
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

    [self hideSearchFieldBehindNavigationBar];
}

- (void)hideSearchFieldBehindNavigationBar
{
    self.tableView.contentOffset = CGPointMake(0, self.searchController.searchBar.frame.size.height);
}

#pragma mark - MCLLoadingContentViewControllerDelegate

- (NSString *)loadingViewControllerRequestsTitleString:(MCLLoadingViewController *)loadingViewController
{
    return self.board.name;
}

- (void)loadingViewController:(MCLLoadingViewController *)loadingViewController configureNavigationItem:(UINavigationItem *)navigationItem
{
    if (self.bag.loginManager.isLoginValid) {
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

- (void)configureDraftBar
{
    if (![self.bag.features isFeatureWithNameEnabled:MCLFeatureDrafts]) {
        return;
    }

    if (!self.bag.draftManager.current) {
        return;
    }

    MCLDraftBarView *draftBarView = [[MCLDraftBarView alloc] initWithBag:self.bag];
//    UIBarButtonItem *draftItem = [[UIBarButtonItem alloc] initWithCustomView:draftBarView];
//    self.bag.router.splitViewController.toolbarItems = @[draftItem];
//
//    self.bag.router.splitViewController.navigationController.toolbar.hidden = NO;
//    [self.bag.router.splitViewController.navigationController setToolbarHidden:NO animated:NO];

    draftBarView.translatesAutoresizingMaskIntoConstraints = NO;
    UIView *splitsView = self.bag.router.splitViewController.view;
    [splitsView addSubview:draftBarView];
    [splitsView.bottomAnchor constraintEqualToAnchor:draftBarView.bottomAnchor];
}


- (NSArray<__kindof UIBarButtonItem *> *)loadingViewControllerRequestsToolbarItems:(MCLLoadingViewController *)loadingViewController
{
    if (![self.bag.features isFeatureWithNameEnabled:MCLFeatureDrafts]) {
        return nil;
    }

    if (!self.bag.draftManager.current) {
        return nil;
    }

    MCLDraftBarView *draftBarView = [[MCLDraftBarView alloc] initWithBag:self.bag];
    UIBarButtonItem *draftItem = [[UIBarButtonItem alloc] initWithCustomView:draftBarView];

    return @[draftItem];
}

- (void)draftButtonPressed:(id)sender
{
    [self.bag.router modalToEditDraft:self.bag.draftManager.current];
    //    MCLComposeMessageViewController *composeMessageVC = [self.bag.router modalToEditDraft:self.bag.draftManager.current];
    //    composeMessageVC.delegate = self;
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
    cell.loginManager = self.bag.loginManager;
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

    if (self.bag.loginManager.isLoginValid) {
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

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.isLoadingThread ? nil : indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MCLThread *thread = [self isSearching] ? self.searchResults[indexPath.row] : self.threads[indexPath.row];
    MCLThreadTableViewCell *cell = (MCLThreadTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell markRead];

    thread.board = self.board;
    thread.tempRead = YES;

    self.isLoadingThread = YES;
    MCLMessageListViewController *messageListVC = [self.bag.router pushToThread:thread];
    if ([messageListVC isKindOfClass:[MCLMessageListViewController class]]) {
        messageListVC.delegate = self;
    }
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    void (^markThreadAsRead)(UITableViewRowAction *action, NSIndexPath *indexPath) = ^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        MCLThread *selectedThread = [self isSearching] ? self.searchResults[indexPath.row] : self.threads[indexPath.row];
        self.tableView.editing = NO;
        [[[MCLMarkThreadAsReadRequest alloc] initWithClient:self.bag.httpClient thread:selectedThread] loadWithCompletionHandler:^(NSError *error, NSArray *data) {
            if (error) {
                [self presentError:error];
                return;
            }

            MCLThreadTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            [cell markRead];
            selectedThread.read = YES;
            selectedThread.lastMessageRead = YES;
            selectedThread.messagesRead = selectedThread.messagesCount;
            [cell updateBadgeWithThread:selectedThread andTheme:self.currentTheme];
            [self.bag.soundEffectPlayer playMarkAllAsReadSound];
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

        if (thread.isFavorite) {
            [self.bag.soundEffectPlayer playAddThreadToFavoritesSound];
        } else {
            [self.bag.soundEffectPlayer playRemoveThreadFromFavoritesSound];
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

- (void)composeMessageViewController:(MCLComposeMessagePreviewViewController *)composeMessageViewController sentMessage:(MCLMessage *)message
{
    [self.loadingViewController refresh];

    NSString *alertMessage = [NSString stringWithFormat:NSLocalizedString(@"Thank you for your contribution \"%@\"", nil), message.subject];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Confirmation", nil)
                                                                   message:alertMessage
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];

    [self.bag.soundEffectPlayer playCreatePostingSound];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)composeMessageViewController:(MCLComposeMessageViewController *)composeMessageViewController dismissedWithMessage:(MCLMessage *)message
{
    if (message) {
        [self.loadingViewController updateToolbar];
//        [self configureDraftBar];
    }
}

#pragma mark - MCLMessageListDelegate

- (void)messageListViewController:(MCLMessageListViewController *)inController didFinishLoadingThread:(MCLThread *)inThread
{
    self.isLoadingThread = NO;
}

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


#pragma mark - ThreadsKeyboardShortcutsDelegate

- (void)keyboardShortcutComposeThreadPressed
{
    [self composeThreadButtonPressed:nil];
}

- (void)keyboardShortcutSelectPreviousThreadPressed
{
    NSIndexPath *selectedIndexPath = self.tableView.indexPathForSelectedRow;
    if (selectedIndexPath && selectedIndexPath.row > 0) {
        NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:selectedIndexPath.row - 1 inSection:0];
        [self.tableView selectRowAtIndexPath:nextIndexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
        [self tableView:self.tableView didSelectRowAtIndexPath:nextIndexPath];
    }
}

- (void)keyboardShortcutSelectNextThreadPressed
{
    NSIndexPath *selectedIndexPath = self.tableView.indexPathForSelectedRow;
    if (selectedIndexPath) {
        if (selectedIndexPath.row < ([self.threads count] - 1)) {
            NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:selectedIndexPath.row + 1 inSection:0];
            [self.tableView selectRowAtIndexPath:nextIndexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
            [self tableView:self.tableView didSelectRowAtIndexPath:nextIndexPath];
        }
    } else { // Select first
        NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView selectRowAtIndexPath:nextIndexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
        [self tableView:self.tableView didSelectRowAtIndexPath:nextIndexPath];
    }
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

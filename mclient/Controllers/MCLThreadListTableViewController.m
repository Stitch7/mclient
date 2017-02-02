//
//  MCLThreadListTableViewController.m
//  mclient
//
//  Created by Christopher Reitz on 25.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLThreadListTableViewController.h"

#import "constants.h"
#import "KeychainItemWrapper.h"
#import "MCLAppDelegate.h"
#import "MCLMServiceConnector.h"
#import "MCLThemeManager.h"
#import "MCLMessageListViewController.h"
#import "MCLMServiceErrorView.h"
#import "MCLInternetConnectionErrorView.h"
#import "MCLLoadingView.h"
#import "MCLThreadTableViewCell.h"
#import "MCLThread.h"
#import "MCLBoard.h"
#import "MCLBadgeView.h"

@interface MCLThreadListTableViewController ()

@property (strong, nonatomic) MCLMessageListViewController *detailViewController;
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (strong, nonatomic) id <MCLTheme> currentTheme;
@property (strong, nonatomic) NSMutableArray *threads;
@property (strong, nonatomic) UISearchController *searchController;
@property (strong, nonatomic) NSTimer *searchTimer;
@property (strong, nonatomic) NSMutableArray *searchResults;
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *password;
@property (assign, nonatomic) BOOL validLogin;
@property (strong, nonatomic) NSDateFormatter *dateFormatterForInput;
@property (strong, nonatomic) NSDateFormatter *dateFormatterForOutput;

@end

@implementation MCLThreadListTableViewController

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

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
    }

    NSString *keychainIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:keychainIdentifier
                                                                            accessGroup:nil];
    self.username = [keychainItem objectForKey:(__bridge id)(kSecAttrAccount)];
    NSData *passwordData = [keychainItem objectForKey:(__bridge id)(kSecValueData)];
    self.password = [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];

    self.validLogin = [[NSUserDefaults standardUserDefaults] boolForKey:@"validLogin"];

    self.dateFormatterForInput = [[NSDateFormatter alloc] init];
    [self.dateFormatterForInput setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    [self.dateFormatterForInput setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];

    self.dateFormatterForOutput = [[NSDateFormatter alloc] init];
    [self.dateFormatterForOutput setDoesRelativeDateFormatting:YES];
    [self.dateFormatterForOutput setDateStyle:NSDateFormatterShortStyle];
    [self.dateFormatterForOutput setTimeStyle:NSDateFormatterShortStyle];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    UINib *threadCellNib = [UINib nibWithNibName: @"MCLThreadTableViewCell" bundle: nil];
    [self.tableView registerNib: threadCellNib forCellReuseIdentifier: @"ThreadCell"];

    [self configureSearchResultsController];

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

        self.detailViewController.delegate = self;
    }

    // Cache original tables separatorColor and set to clear to avoid flickering loading view
    [self.tableView setSeparatorColor:[UIColor clearColor]];

    // Set title to board name
    self.title = self.board.name;

    if (!self.validLogin) {
        self.navigationItem.rightBarButtonItem = nil;
    }
    
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
        NSDictionary *loginData;
        if (self.validLogin) {
            loginData = @{@"username":self.username, @"password":self.password};
        }
        NSDictionary *data = [[MCLMServiceConnector sharedConnector] threadsFromBoardId:self.board.boardId
                                                                                  login:loginData
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
    UITextField *searchField = [self searchViewForTextFieldBg:self.searchController.searchBar];
    [searchField setBackgroundColor:[self.currentTheme searchFieldBackgroundColor]];
    [searchField setTextColor:[self.currentTheme searchFieldTextColor]];
}

- (UITextField*)searchViewForTextFieldBg:(UIView*)view
{
    if ([view isKindOfClass:[UITextField class]]) {
        return (UITextField *)view;
    }

    UITextField *searchTextField;
    for (UIView *subview in view.subviews) {
        searchTextField = [self searchViewForTextFieldBg:subview];
        if (searchTextField) {
            break;
        }
    }
    return searchTextField;
}

- (void)reloadData
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *mServiceError;
        NSDictionary *loginData;
        if (self.validLogin) {
            loginData = @{@"username":self.username, @"password":self.password};
        }
        NSDictionary *data = [[MCLMServiceConnector sharedConnector] threadsFromBoardId:self.board.boardId
                                                                                  login:loginData
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
        if (error.code == -2) {
            [self.view addSubview:[[MCLInternetConnectionErrorView alloc] initWithFrame:self.view.frame]];
        }
        else {
            MCLMServiceErrorView *mServiceErrorView = [[MCLMServiceErrorView alloc] initWithFrame:self.view.frame
                                                                                          andText:[error localizedDescription]];
            [self.view addSubview:mServiceErrorView];
        }
    } else {
        self.threads = [NSMutableArray array];
        for (id object in data) {
            [self.threads addObject:[self threadFromJSON:object]];
        }

        // Restore tables separatorColor
        [self.tableView setSeparatorColor:[self.currentTheme tableViewSeparatorColor]];

        [self.tableView reloadData];

        // Hide search bar behind navigation bar
        NSIndexPath *topIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView scrollToRowAtIndexPath:topIndexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

- (MCLThread *)threadFromJSON:(id)object
{
    NSNumber *threadId = [object objectForKey:@"id"];
    NSNumber *messageId = [object objectForKey:@"messageId"];
    id isRead = [object objectForKey:@"isRead"];
    BOOL read = isRead != (id)[NSNull null] ? [isRead boolValue] : YES;
    BOOL sticky = [[object objectForKey:@"sticky"] boolValue];
    BOOL closed = [[object objectForKey:@"closed"] boolValue];
    BOOL mod = [[object objectForKey:@"mod"] boolValue];
    NSString *username = [object objectForKey:@"username"];
    NSString *subject = [object objectForKey:@"subject"];
    NSDate *date = [self.dateFormatterForInput dateFromString:[object objectForKey:@"date"]];
    NSNumber *messagesCount = [object objectForKey:@"messagesCount"];
    id messagesReadOpt = [object objectForKey:@"messagesRead"];
    NSNumber *messagesRead = messagesReadOpt != (id)[NSNull null] ? messagesReadOpt : messagesCount;
    NSNumber *lastMessageId = [object objectForKey:@"lastMessageId"];
    id lastMessageReadOpt = [object objectForKey:@"lastMessageIsRead"];
    BOOL lastMessageRead = lastMessageReadOpt != (id)[NSNull null] ? [lastMessageReadOpt boolValue] : YES;
    NSDate *lastMessageDate = [self.dateFormatterForInput dateFromString:[object objectForKey:@"lastMessageDate"]];

    return [MCLThread threadWithId:threadId
                         messageId:messageId
                              read:read
                            sticky:sticky
                            closed:closed
                               mod:mod
                          username:username
                           subject:subject
                              date:date
                      messagesCount:messagesCount
                      messagesRead:messagesRead
                     lastMessageId:lastMessageId
                     lastMessageRead:lastMessageRead
                   lastMessageDate:lastMessageDate];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self isSearching] ? [self.searchResults count] : [self.threads count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"ThreadCell";

    MCLThreadTableViewCell *cell =
        (MCLThreadTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    cell.separatorInset = UIEdgeInsetsZero;

    UIView *backgroundView = [[UIView alloc] initWithFrame:cell.frame];
    backgroundView.backgroundColor = [self.currentTheme tableViewCellSelectedBackgroundColor];
    cell.selectedBackgroundView = backgroundView;

    MCLThread *thread = [self isSearching] ? self.searchResults[indexPath.row] : self.threads[indexPath.row];
    cell.thread = thread;

    cell.threadSubjectLabel.text = thread.subject;

    cell.threadUsernameLabel.text = thread.username;
    if ([thread.username isEqualToString:self.username]) {
        cell.threadUsernameLabel.textColor = [self.currentTheme ownUsernameTextColor];
    } else if (thread.isMod) {
        cell.threadUsernameLabel.textColor = [self.currentTheme modTextColor];
    } else {
        cell.threadUsernameLabel.textColor = [self.currentTheme usernameTextColor];
    }
    
    cell.threadDateLabel.text = [self.dateFormatterForOutput stringFromDate:thread.date];
    cell.threadDateLabel.textColor = [self.currentTheme detailTextColor];

    if (thread.isRead || thread.isTemporaryRead || thread.isClosed) {
        [cell markRead];
    } else {
        [cell markUnread];
    }

    if (thread.isSticky || thread.isClosed) {
        cell.readSymbolViewLeadingConstraint.constant = 23.0f;
    }
    else {
        cell.readSymbolViewLeadingConstraint.constant = 7.0f;
    }

    cell.threadIsStickyImageView.image = [cell.threadIsStickyImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    cell.threadIsStickyImageView.tintColor = [self.currentTheme detailImageColor];
    [cell.threadIsStickyImageView setHidden:!thread.isSticky];

    cell.threadIsClosedImageView.image = [cell.threadIsClosedImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    cell.threadIsClosedImageView.tintColor = [self.currentTheme detailImageColor];
    [cell.threadIsClosedImageView setHidden:!thread.isClosed];

    cell.badgeView.userInteractionEnabled = NO;
    cell.badgeLabel.userInteractionEnabled = NO;

    [cell updateBadgeWithThread:thread andTheme:self.currentTheme];

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    MCLThread *thread = [self isSearching] ? self.searchResults[indexPath.row] : self.threads[indexPath.row];
    BOOL hasUnreadMessages = thread.messagesRead < thread.messagesCount;

    return hasUnreadMessages;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    // this method must be implement too or nothing will work
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
    thread.tempRead = YES;
    // Workaround for swipe back
//    if ([thread.messagesCount intValue] == 0) {
//        cell.badgeLabel.textColor = [UIColor darkGrayColor];
//    }

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        // Hide popoverController in portrait mode
        if (!UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])) {
            [self.masterPopoverController dismissPopoverAnimated:YES];
        }

        [self.detailViewController loadThread:thread fromBoard:self.board];
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

-(NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    void (^markThreadAsRead)(UITableViewRowAction *action, NSIndexPath *indexPath) = ^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        MCLThread *selectedThread = [self isSearching] ? self.searchResults[indexPath.row] : self.threads[indexPath.row];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError *mServiceError;
            NSDictionary *loginData;
            if (self.validLogin) {
                loginData = @{@"username":self.username, @"password":self.password};
            }
            NSDictionary *data = [[MCLMServiceConnector sharedConnector] markAsReadThreadWithId:selectedThread.threadId
                                                                                    fromBoardId:self.board.boardId
                                                                                          login:loginData
                                                                                          error:&mServiceError];

            dispatch_async(dispatch_get_main_queue(), ^{
                if (mServiceError) { // TODO: Display error to user
                    NSLog(@"%@ - %@", mServiceError, data);
                } else {
                    MCLThreadTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                    [cell markRead];
                    selectedThread.read = YES;
                    selectedThread.lastMessageRead = YES;
                    selectedThread.messagesRead = selectedThread.messagesCount;
                    [cell updateBadgeWithThread:selectedThread andTheme:self.currentTheme];
                }

                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                self.tableView.editing = NO;
            });
        });
    };

    UITableViewRowAction *button = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault
                                                                      title:NSLocalizedString(@"Mark as read", nil)
                                                                    handler:markThreadAsRead];
    button.backgroundColor = [self.currentTheme tintColor];

    return @[button];
}

#pragma mark - MCLComposeMessageViewControllerDelegate

- (void)messageSentWithType:(NSUInteger)type
{
    [self reloadData];
}

#pragma mark - MCLMessageListDelegate

- (void)messageListViewController:(MCLMessageListViewController *)inController didReadMessageOnThread:(MCLThread *)inThread
{
    NSIndexPath *selectedIndexPath = self.tableView.indexPathForSelectedRow;
    MCLThreadTableViewCell *selectedCell = [self.tableView cellForRowAtIndexPath:selectedIndexPath];
    [selectedCell updateBadgeWithThread:inThread andTheme:self.currentTheme];
}

#pragma mark - UISearchResultsUpdating

- (BOOL)isSearching
{
    return self.searchController.isActive;
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

-(void)searchTimerPopped:(NSTimer *)searchTimer
{
    [self doSearch:searchTimer.userInfo];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self doSearch:searchBar.text];
}

- (void)doSearch:(NSString *)searchString
{
    NSError *mServiceError;
    NSDictionary *loginData;
    if (self.validLogin) {
        loginData = @{@"username":self.username, @"password":self.password};
    }
    NSDictionary *data = [[MCLMServiceConnector sharedConnector] searchThreadsOnBoard:self.board.boardId
                                                                           withPhrase:searchString
                                                                                login:loginData
                                                                                error:&mServiceError];

    if (mServiceError) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                    message:[mServiceError localizedDescription]
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];

    } else {
        self.searchResults = [NSMutableArray array];
        for (id object in data) {
            [self.searchResults addObject:[self threadFromJSON:object]];
        }

        [self.tableView reloadData];
    }
}

#pragma mark - Notifications

- (void)themeChanged:(NSNotification *)notification
{
    self.currentTheme = [[MCLThemeManager sharedManager] currentTheme];
    [self configureSearchResultsController];
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
        MCLThread *thread = [self isSearching] ? self.searchResults[indexPath.row] : self.threads[indexPath.row];
        MCLMessageListViewController *messageListVC = segue.destinationViewController;
        [messageListVC setDelegate:self];
        [messageListVC setBoard:self.board];
        [messageListVC setThread:thread];
    } else if ([segue.identifier isEqualToString:@"ModalToComposeThread"]) {
        MCLComposeMessageViewController *composeThreadVC =
            ((MCLComposeMessageViewController *)[[segue.destinationViewController viewControllers] objectAtIndex:0]);
        [composeThreadVC setDelegate:self];
        [composeThreadVC setType:kMCLComposeTypeThread];
        [composeThreadVC setBoardId:self.board.boardId];
    }
}

@end

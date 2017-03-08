//
//  MCLBoardListTableViewController.m
//  mclient
//
//  Created by Christopher Reitz on 21.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLBoardListTableViewController.h"

#import "BBBadgeBarButtonItem.h"

#import "KeychainItemWrapper.h"
#import "MCLAppDelegate.h"
#import "MCLMServiceConnector.h"
#import "MCLMessageResponsesClient.h"
#import "MCLTheme.h"
#import "MCLThemeManager.h"
#import "MCLThreadListTableViewController.h"
#import "MCLMessageListViewController.h"
#import "MCLBoard.h"
#import "MCLMServiceErrorView.h"
#import "MCLInternetConnectionErrorView.h"
#import "MCLLoadingView.h"
#import "MCLVerifiyLoginView.h"

@interface MCLBoardListTableViewController ()

@property (strong, nonatomic) id <MCLTheme> currentTheme;
@property (strong, nonatomic) NSMutableArray *boards;
@property (strong, nonatomic) NSDictionary *images;
@property (strong, nonatomic) MCLMessageResponsesClient *messageResponsesClient;
@property (strong, nonatomic) BBBadgeBarButtonItem *responsesButtonItem;

@end

@implementation MCLBoardListTableViewController

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

    if (self.splitViewController) {
        [self.splitViewController setDelegate:self];
    }

    self.images = @{@1: @"boardSmalltalk.png",
                    @2: @"boardForSale.png",
                    @4: @"boardRetroNTech.png",
                    @6: @"boardOT.png",
                    @26: @"boardKulturbeutel.png",
                    @8: @"boardOnlineGaming.png"};

    self.messageResponsesClient = [[MCLMessageResponsesClient alloc] init];
    self.messageResponsesClient.delegate = self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self configureNavigationBar];
    [self configureRefreshControl];
    [self configureResponsesButton];

    // Visualize loading
    [self.view addSubview:[[MCLLoadingView alloc] initWithFrame:self.view.frame]];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    // Load data async
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *mServiceError;
        NSDictionary *data = [[MCLMServiceConnector sharedConnector] boards:&mServiceError];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self fetchedData:data error:mServiceError];
        });
    });
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self showLoginStatus];
    [self.tableView reloadData];

    self.currentTheme = [[MCLThemeManager sharedManager] currentTheme];

    // Fix odd glitch on swipe back causing cell stay selected
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (selectedIndexPath) {
        [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
    }
}

- (void)showLoginStatus
{
    // Remove if already present
    for (id subview in self.navigationController.toolbar.subviews) {
        if ([[subview class] isSubclassOfClass: [MCLVerifiyLoginView class]]) {
            [subview removeFromSuperview];
        }
    }

    // TODO: Both calls are required? Why?
    [self.navigationController setToolbarHidden:NO animated:NO];
    self.navigationController.toolbar.hidden = NO;

    CGRect verifyLoginViewFrame = self.navigationController.toolbar.bounds;
    verifyLoginViewFrame.size.width = verifyLoginViewFrame.size.width - 150.0f;
    MCLVerifiyLoginView *verifyLoginView = [[MCLVerifiyLoginView alloc] initWithFrame:verifyLoginViewFrame];
    UIBarButtonItem *verifyLoginViewItem = [[UIBarButtonItem alloc] initWithCustomView:verifyLoginView];

    self.toolbarItems = [NSArray arrayWithObjects:self.responsesButtonItem, verifyLoginViewItem, nil];

    // Reading username + password from keychain
    NSString *keychainIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:keychainIdentifier
                                                                            accessGroup:nil];
    [keychainItem setObject:(__bridge id)(kSecAttrAccessibleWhenUnlocked) forKey:(__bridge id)(kSecAttrAccessible)];
    NSData *passwordData = [keychainItem objectForKey:(__bridge id)(kSecValueData)];
    NSString *password = [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];
    NSString *username = [keychainItem objectForKey:(__bridge id)(kSecAttrAccount)];

    if (username.length == 0 || password.length == 0) {
        [self saveValidLoginFlagWithValue:NO];
        [verifyLoginView loginStatusNoLogin];
    } else {
        // Check login data async
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError *mServiceError;
            [[MCLMServiceConnector sharedConnector] testLoginWithUsername:username
                                                                 password:password
                                                                    error:&mServiceError];

            // Set login status on main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                if (mServiceError) {
                    if ([mServiceError code] == 401) {
                        [verifyLoginView loginStatusNoLogin];
                        [self saveValidLoginFlagWithValue:NO];
                    } else {
                        [self.navigationController setToolbarHidden:YES animated:YES];
                    }
                } else {
                    [verifyLoginView loginStatusWithUsername:username];
                    [self saveValidLoginFlagWithValue:YES];

                    [self.messageResponsesClient loadData];
                }
            });
        });
    }
}

- (void)saveValidLoginFlagWithValue:(BOOL)validLogin
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:validLogin forKey:@"validLogin"];
    [self.responsesButtonItem setEnabled:validLogin];
}

- (void)configureNavigationBar
{
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settingsButton.png"]
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(settingsButtonPressed:)];
    self.navigationItem.rightBarButtonItem = settingsButton;
}

- (void)configureRefreshControl
{
    if (self.refreshControl) { return; }

    self.tableView.bounces = YES;

    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}

- (void)configureResponsesButton
{
    UIImage *responsesImage = [[UIImage imageNamed:@"responsesButton.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIButton *responsesButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 50.0f, 50.0f)];
    [responsesButton setImage:responsesImage forState:UIControlStateNormal];
    [responsesButton addTarget:self action:@selector(responsesButtonTapped) forControlEvents:UIControlEventTouchUpInside];

    self.responsesButtonItem = [[BBBadgeBarButtonItem alloc] initWithCustomUIButton:responsesButton];
    self.responsesButtonItem.badgeOriginX = 0.0f;
    self.responsesButtonItem.badgeOriginY = 8.0f;
    self.responsesButtonItem.badgeValue = @"0";
    self.responsesButtonItem.shouldHideBadgeAtZero = YES;
    self.responsesButtonItem.badgePadding = 5;
}

- (void)responsesButtonTapped
{
    [self performSegueWithIdentifier:@"ModalToResponses" sender:nil];
}

- (void)reloadData
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *mServiceError;
        NSDictionary *data = [[MCLMServiceConnector sharedConnector] boards:&mServiceError];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self fetchedData:data error:mServiceError];
            if (!mServiceError) {
                [self showLoginStatus];
            }
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
            [self.tableView addSubview:mServiceErrorView];
        }
    } else {
        self.boards = [NSMutableArray array];
        for (id object in data) {
            NSNumber *boardId = [object objectForKey:@"id"];
            NSString *boardName = [object objectForKey:@"name"];
            if ([boardId isEqual:[NSNull null]] || boardName.length == 0) {
                continue;
            }

            MCLBoard *board = [MCLBoard boardWithId:boardId name:boardName];
            [self.boards addObject:board];
        }

        [self.tableView reloadData];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.boards count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"BoardCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    UIView *backgroundView = [[UIView alloc] initWithFrame:cell.frame];
    backgroundView.backgroundColor = [self.currentTheme tableViewCellSelectedBackgroundColor];
    cell.selectedBackgroundView = backgroundView;

    MCLBoard *board = self.boards[indexPath.row];

    NSString *imageName = [self.images objectForKey:board.boardId];
    cell.imageView.image = imageName ? [UIImage imageNamed:imageName] : [UIImage imageNamed:@"boardDefault.png"];

    cell.textLabel.text = board.name;

    return cell;
}

#pragma mark - MCLMessageResponsesClientDelegate 

- (void)messageResponsesClient:(MCLMessageResponsesClient *)client foundUnreadResponses:(NSNumber *)numberOfUnreadResponses
{
    self.responsesButtonItem.badgeValue = [numberOfUnreadResponses stringValue];
}

- (void)messageResponsesClient:(MCLMessageResponsesClient *)client fetchedData:(NSMutableDictionary *)responses sectionKeys:(NSMutableArray *)sectionKeys sectionTitles:(NSMutableDictionary *)sectionTitles
{
}

- (void)messageResponsesClient:(MCLMessageResponsesClient *)client failedWithError:(NSError *)error
{
}

#pragma mark - MCLSettingsTableViewControllerDelegate

- (void)settingsTableViewControllerDidFinish:(MCLSettingsTableViewController *)inController loginDataChanged:(BOOL)loginDataChanged
{
    if (loginDataChanged) {
        [self showLoginStatus];
    }
}

#pragma mark - UISplitViewControllerDelegate

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    UINavigationController *navController = [[[self splitViewController] viewControllers] lastObject];
    MCLMessageListViewController *detailViewController = [[navController viewControllers] firstObject];
    [detailViewController setSplitViewButton:barButtonItem forPopoverController:popoverController];
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    UINavigationController *navController = [[[self splitViewController] viewControllers] lastObject];
    MCLMessageListViewController *detailViewController = [[navController viewControllers] firstObject];
    [detailViewController setSplitViewButton:nil forPopoverController:nil];
}

#pragma mark - Actions

- (void)settingsButtonPressed:(UIBarButtonItem *)sender
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Settings" bundle:nil];
    UINavigationController *nc = [sb instantiateViewControllerWithIdentifier:@"SettingsNavigationController"];
    nc.modalPresentationStyle = UIModalPresentationFormSheet;
    MCLSettingsTableViewController *settingsVC = nc.viewControllers[0];
    settingsVC.delegate = self;
    [self.navigationController presentViewController:nc animated:YES completion:nil];
}

#pragma mark - Notifications

- (void)themeChanged:(NSNotification *)notification
{
    self.currentTheme = [[MCLThemeManager sharedManager] currentTheme];
    [self.tableView reloadData];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"PushToThreadList"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        MCLBoard *board = self.boards[indexPath.row];
        [segue.destinationViewController setBoard:board];
    }
}

@end

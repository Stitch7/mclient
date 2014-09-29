//
//  MCLBoardListTableViewController.m
//  mclient
//
//  Created by Christopher Reitz on 21.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "constants.h"
#import "Reachability.h"
#import "KeychainItemWrapper.h"
#import "MCLMServiceConnector.h"
#import "MCLBoardListTableViewController.h"
#import "MCLThreadListTableViewController.h"
#import "MCLMessageListViewController.h"
#import "MCLBoard.h"
#import "MCLErrorView.h"
#import "MCLMServiceErrorView.h"
#import "MCLInternetConnectionErrorView.h"
#import "MCLLoadingView.h"
#import "MCLVerifiyLoginView.h"

@interface MCLBoardListTableViewController ()

@property (assign, nonatomic) BOOL preselectedBoardSequePerformed;
@property (assign, nonatomic) CGRect tableViewBounds;
@property (strong, nonatomic) NSMutableArray *boards;
@property (strong, nonatomic) Reachability *reachability;
@property (strong, nonatomic) NSDictionary *images;

@end

@implementation MCLBoardListTableViewController

- (void)awakeFromNib
{
    [super awakeFromNib];

    if (self.splitViewController) {
        [self.splitViewController setDelegate:self];
    }

    self.images = @{ @1: @"boardSmalltalk.png",
                     @2: @"boardForSale.png",
                     @4: @"boardTechNCheats.png",
                     @6: @"boardOT.png",
                    @26: @"boardKulturbeutel.png",
                     @8: @"boardOnlineGaming.png"};
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (self.preselectedBoard && ! self.preselectedBoardSequePerformed) { // Method is called twice
        self.preselectedBoardSequePerformed = YES;
        [self performSegueWithIdentifier:@"PushToThreadListNoAnimation" sender:nil];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    BOOL isPortrait =
        self.interfaceOrientation == UIInterfaceOrientationPortrait ||
        self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown
    ;

    BOOL isLandscape =
        self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
        self.interfaceOrientation == UIInterfaceOrientationLandscapeRight
    ;

    // Fix width for when in splitView
    CGFloat viewWidth = self.splitViewController ? 320 : self.view.bounds.size.width;

    CGFloat viewHeight = self.view.bounds.size.height;
    // If iPad starts in landscape mode, subtract some points...
    viewHeight = isLandscape && self.splitViewController ? viewHeight - 250 : viewHeight;
    // Add missing navBar points in landscape mode for iPhone
    viewHeight = self.splitViewController ? viewHeight : viewHeight + 12;

    CGFloat navBarHeight = self.navigationController.navigationBar.bounds.size.height;

    CGSize statusBarSize = [UIApplication sharedApplication].statusBarFrame.size;
    CGFloat statusBarHeight = (isPortrait ? statusBarSize.height : statusBarSize.width);

    self.tableViewBounds = CGRectMake(0, 0, viewWidth, viewHeight - navBarHeight - statusBarHeight);

    [self showLoginStatus];
    // [self setupReachability];
    [self setupRefreshControl];

    [self.view addSubview:[[MCLLoadingView alloc] initWithFrame:self.tableViewBounds]];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [self loadData];
        [self performSelectorOnMainThread:@selector(fetchedData:) withObject:data waitUntilDone:YES];
    });
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

//    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//    for (id key in @[@"signatureEnabled", @"signatureText", @"frameStyle", @"nightMode", @"syncReadStatus"]) {
//        NSLog(@"%@: %@", key, [userDefaults objectForKey:key]);
//    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showLoginStatus
{
    // Remove if already present
    for (id subview in self.navigationController.toolbar.subviews) {
        if ([[subview class] isSubclassOfClass: [MCLVerifiyLoginView class]]) {
            [subview removeFromSuperview];
        }
    }

    // Add VerifiyLoginView to navigationControllers toolbar
    CGRect navToolbarFrane = CGRectMake(0, 0, self.tableViewBounds.size.width, self.navigationController.toolbar.bounds.size.height);
    MCLVerifiyLoginView *navToolbarView = [[MCLVerifiyLoginView alloc] initWithFrame:navToolbarFrane];
    [self.navigationController.toolbar addSubview:navToolbarView];
    [self.navigationController setToolbarHidden:NO animated:YES];

    // Reading username + password from keychain
    NSString *keychainIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:keychainIdentifier accessGroup:nil];
    [keychainItem setObject:(__bridge id)(kSecAttrAccessibleWhenUnlocked) forKey:(__bridge id)(kSecAttrAccessible)];
    NSData *passwordData = [keychainItem objectForKey:(__bridge id)(kSecValueData)];
    NSString *password = [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];
    NSString *username = [keychainItem objectForKey:(__bridge id)(kSecAttrAccount)];

    // Check login data async
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL loginValid = NO;
        if ([username length] > 0 && [password length] > 0) {
            NSError *error;
            loginValid = ([[[MCLMServiceConnector alloc] init] testLoginWIthUsername:username password:password error:&error]);
        }

        // Set login status on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            if (loginValid) {
                [navToolbarView loginStatusWithUsername:username];
            } else {
                [navToolbarView loginStausNoLogin];
            }
        });
    });
}

- (NSData *)loadData
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSString *urlString = [NSString stringWithFormat:@"%@/", kMServiceBaseURL];
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString: urlString]];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    return data;
}

- (void)setupRefreshControl
{
    if ( ! self.refreshControl) {
        self.tableView.bounces = YES;

        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
        self.refreshControl = refreshControl;
    }
}

- (void)stopRefresh
{
    [self.refreshControl endRefreshing];
}

- (void)reloadData
{
    NSData *data = [self loadData];
    [self fetchedData:data];
//    [self performSelector:@selector(stopRefresh) withObject:nil afterDelay:1.5]; // 1.5
    [self showLoginStatus];
    [self stopRefresh];
}

- (void)fetchedData:(NSData *)data
{
    if ( ! data) {
        BOOL errorViewPresent = NO;
        for (id subview in self.view.subviews) {
            if ([[subview class] isSubclassOfClass: [MCLErrorView class]]) {
                errorViewPresent = YES;
            }
        }

        if ( ! errorViewPresent) {
            [self.view addSubview:[[MCLMServiceErrorView alloc] initWithFrame:self.tableViewBounds]];
        }
    } else {
        self.boards = [NSMutableArray array];

        NSError *error;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        for (id object in json) {
            NSNumber *boardId = [object objectForKey:@"id"];
            NSString *boardName = [object objectForKey:@"text"];

            MCLBoard *board = [MCLBoard boardWithId:boardId name:boardName];
            [self.boards addObject:board];
        }

        for (id subview in self.view.subviews) {
            if ([[subview class] isSubclassOfClass: [MCLErrorView class]]) {
                [subview removeFromSuperview];
            } else if ([[subview class] isSubclassOfClass: [MCLLoadingView class]]) {
                [subview removeFromSuperview];
            }
        }
        [self.tableView reloadData];
    }
}


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.boards count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MCLBoard *board = self.boards[indexPath.row];

    static NSString *cellIdentifier = @"BoardCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    NSString *imageName = [self.images objectForKey:board.boardId];
    cell.imageView.image = imageName ? [UIImage imageNamed:imageName] : [UIImage imageNamed:@"boardDefault.png"];

    cell.textLabel.text = board.name;

    return cell;
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


#pragma mark - Reachability

- (void)setupReachability
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
	self.reachability = [Reachability reachabilityWithHostName:@"www.google.com"];
	[self.reachability startNotifier];
	[self updateInterfaceWithReachability:self.reachability];
}

- (void) reachabilityChanged:(NSNotification *)note
{
//    NSLog(@"reachabilityChanged");

	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
	[self updateInterfaceWithReachability:curReach];
}

- (void)updateInterfaceWithReachability:(Reachability *)reachability
{
    NetworkStatus netStatus = [reachability currentReachabilityStatus];

//    NSLog(@"#NetworkStatus = %i", netStatus);

    switch (netStatus) {
        case NotReachable:
//            NSLog(@"-- NotReachable");
            [self.view addSubview:[[MCLInternetConnectionErrorView alloc] initWithFrame:self.tableViewBounds]];
            self.refreshControl = nil;
            self.tableView.bounces = NO;
            break;


        case ReachableViaWWAN:
        case ReachableViaWiFi:
//            NSLog(@"-- ReachableVia");
            for (id subview in self.view.subviews) {
                if ([[subview class] isSubclassOfClass: [MCLErrorView class]]) {
                    [subview removeFromSuperview];
                    [self setupRefreshControl];
                }
            }
            break;
    }
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"PushToThreadList"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        MCLBoard *board = self.boards[indexPath.row];
        [segue.destinationViewController setBoard:board];
    } else if ([segue.identifier isEqualToString:@"PushToThreadListNoAnimation"]) {
        [segue.destinationViewController setBoard:self.preselectedBoard];
    }
}

@end

//
//  MCLBoardListTableViewController.m
//  mclient
//
//  Created by Christopher Reitz on 21.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "constants.h"
#import "Reachability.h"
#import "MCLBoardListTableViewController.h"
#import "MCLThreadListTableViewController.h"
#import "MCLDetailViewController.h"
#import "MCLBoard.h"
#import "MCLErrorView.h"
#import "MCLLoadingView.h"

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

    [self.splitViewController setDelegate:self];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
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

    [self setupReachability];
    [self setupRefreshControl];

    self.tableViewBounds = self.view.bounds;

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

- (NSData *)loadData
{
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString: kMServiceBaseURL]];

    return data;
}

- (void)setupRefreshControl
{
    if ( ! self.refreshControl) {
        self.tableView.bounces = YES;

        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to refresh..."];
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
            [self.view addSubview:[[MCLErrorView alloc] initWithFrame:self.tableViewBounds]];
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
    UINavigationController *navController = [[[self splitViewController ] viewControllers ] lastObject ];
    MCLDetailViewController *detailViewController = [[navController viewControllers] firstObject];
    [detailViewController setSplitViewButton:barButtonItem forPopoverController:popoverController];
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    UINavigationController *navController = [[[self splitViewController ] viewControllers ] lastObject ];
    MCLDetailViewController *detailViewController = [[navController viewControllers] firstObject];
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
            [self.view addSubview:[[MCLErrorView alloc] initWithFrame:self.tableViewBounds]];
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
    }


    if ([segue.identifier isEqualToString:@"PushToThreadListNoAnimation"]) {
        [segue.destinationViewController setBoard:self.preselectedBoard];
    }
}

@end

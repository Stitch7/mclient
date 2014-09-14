//
//  MCLBoardListTableViewController.m
//  mclient
//
//  Created by Christopher Reitz on 21.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "constants.h"
#import "MCLBoardListTableViewController.h"
#import "MCLThreadListTableViewController.h"
#import "MCLBoard.h"
#import "MCLErrorView.h"
#import "MCLLoadingView.h"

@interface MCLBoardListTableViewController ()

@property (assign, nonatomic) CGRect tableViewBounds;
@property (strong, nonatomic) NSMutableArray *boards;

@end

@implementation MCLBoardListTableViewController

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
    
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    /*
    self.threadListTableViewController = (MCLThreadListTableViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    */

    // Init refresh control
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to refresh..."];
    [refreshControl addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;

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
//    for (id key in @[@"signatureEnabled", @"signatureText", @"nightMode", @"syncReadStatus"]) {
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BoardCell" forIndexPath:indexPath];
    
    cell.textLabel.text = board.name;
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.boards removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}


#pragma mark - Navigation

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        MCLBoard *board = self.boards[indexPath.row];
        [self.threadListTableViewController setBoard: board];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"PushToThreadList"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        MCLBoard *board = self.boards[indexPath.row];
        [segue.destinationViewController setBoard:board];
    }
}

@end

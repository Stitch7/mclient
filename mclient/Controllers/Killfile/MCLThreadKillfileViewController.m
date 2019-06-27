//
//  MCLThreadsKillfileViewController.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLThreadKillfileViewController.h"

#import "MCLDependencyBag.h"
#import "UIViewController+Additions.h"
#import "MCLSoundEffectPlayer.h"
#import "MCLKillfileThreadsRequest.h"
#import "MCLKillfileThreadToggleRequest.h"
#import "MCLTheme.h"
#import "MCLThemeManager.h"
#import "MCLThread.h"
#import "MCLThreadTableViewCell.h"
#import "MCLLoadingView.h"
#import "MCLInternetConnectionErrorView.h"
#import "MCLMServiceErrorView.h"

@interface MCLThreadKillfileViewController ()

@property (strong, nonatomic) NSMutableArray *threads;
@property (strong, nonatomic) id <MCLTheme> currentTheme;

@end

@implementation MCLThreadKillfileViewController

#pragma mark - Initializers

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (!self) return nil;

    self.bag = bag;
    self.currentTheme = self.bag.themeManager.currentTheme;

    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.currentTheme = self.bag.themeManager.currentTheme;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Ausgeblendete Threads";
    [self configureTableView];
    [self configureRefreshControl];
    [self loadThreads];
}

- (void)configureTableView
{
    UINib *threadCellNib = [UINib nibWithNibName:@"MCLThreadTableViewCell" bundle:nil];
    [self.tableView registerNib:threadCellNib forCellReuseIdentifier:MCLThreadTableViewCellIdentifier];

    self.tableView.editing = YES;
}

- (void)configureRefreshControl
{
    if (self.refreshControl) {
        return;
    }

    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}

- (void)reloadData
{
    [self.view addSubview:[[MCLLoadingView alloc] initWithFrame:self.view.frame]];
    [[[MCLKillfileThreadsRequest alloc] init] loadWithCompletionHandler:^(NSError *error, NSArray *threads) {
        [self fetchedThreads:threads error:error];
        [self.refreshControl endRefreshing];
    }];
}

- (void)loadThreads
{
    [self.view addSubview:[[MCLLoadingView alloc] initWithFrame:self.view.frame]];
    [[[MCLKillfileThreadsRequest alloc] init] loadWithCompletionHandler:^(NSError *error, NSArray *threads) {
        [self fetchedThreads:threads error:error];
    }];
}

- (void)fetchedThreads:(NSArray *)threads error:(NSError *)error
{
    [self removeOverlayViews];

    self.threads = [threads mutableCopy];
    [self.tableView reloadData];
}


#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return self.threads.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
   
    MCLThreadTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:MCLThreadTableViewCellIdentifier];
//    cell.login = self.bag.login;
    cell.thread = self.threads[indexPath.row];

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

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self removeThreadFromKillfileAtIndexPath:indexPath];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Wieder anzeigen";
}

- (void)removeThreadFromKillfileAtIndexPath:(NSIndexPath *)indexPath
{
//    MCLThreadTableViewCell *threadCell = [self.tableView cellForRowAtIndexPath:indexPath];
//    MCLThread *thread = self.threads[indexPath.row];

//    [[MCLKillfileThreadToggleRequest alloc] initWithClient:self.bag.httpClient thread:thread]

//    [self.threads removeObjectAtIndex:threadCell.index];
//    [MCLSoundeffectPlayer playRemovedThreadFromKillfileSound];
//    [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row inSection:0]]
//                          withRowAnimation:UITableViewRowAnimationLeft];
}

@end

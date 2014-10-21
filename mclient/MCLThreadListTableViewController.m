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
#import "MCLMessageListWidmannStyleViewController.h" //TODO
#import "MCLMessageListFrameStyleViewController.h" //TODO
#import "MCLMessageListViewController.h"
#import "MCLMServiceErrorView.h"
#import "MCLInternetConnectionErrorView.h"
#import "MCLLoadingView.h"
#import "MCLThreadTableViewCell.h"
#import "MCLThread.h"
#import "MCLBoard.h"
#import "MCLReadList.h"


@interface MCLThreadListTableViewController ()

@property (strong, nonatomic) UIColor *tableSeparatorColor;
@property (strong, nonatomic) MCLMessageListViewController *detailViewController;
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (strong, nonatomic) NSMutableArray *threads;
@property (strong, nonatomic) NSMutableArray *searchResults;
@property (strong, nonatomic) MCLReadList *readList;
@property (strong, nonatomic) NSString *username;
@property (assign, nonatomic) BOOL validLogin;
@property (strong, nonatomic) NSDateFormatter *dateFormatterForInput;
@property (strong, nonatomic) NSDateFormatter *dateFormatterForOutput;

@end

@implementation MCLThreadListTableViewController

- (void)awakeFromNib
{
    [super awakeFromNib];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
    }

    NSString *keychainIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:keychainIdentifier accessGroup:nil];
    self.username = [keychainItem objectForKey:(__bridge id)(kSecAttrAccount)];

    self.validLogin = [[NSUserDefaults standardUserDefaults] boolForKey:@"validLogin"];

    self.dateFormatterForInput = [[NSDateFormatter alloc] init];
    [self.dateFormatterForInput setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    [self.dateFormatterForInput setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];

    self.dateFormatterForOutput = [[NSDateFormatter alloc] init];
    [self.dateFormatterForOutput setDoesRelativeDateFormatting:YES];
    [self.dateFormatterForOutput setDateStyle:NSDateFormatterShortStyle];
    [self.dateFormatterForOutput setTimeStyle:NSDateFormatterShortStyle];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Fix odd glitch on swipe back causing cell stay selected
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (selectedIndexPath) {
        [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
    }

    // Hide bottom toolbar
    [self.navigationController setToolbarHidden:YES animated:NO];

    // Load readlist
    self.readList = [[MCLReadList alloc] init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // On iPad replace splitviews detailViewController with MessageListViewController type depending on users settings
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        NSString *storyboardIdentifier = nil;
        switch ([[NSUserDefaults standardUserDefaults] integerForKey:@"threadView"]) {
            case kMCLSettingsThreadViewWidmann:
                storyboardIdentifier = @"MessageListView";
                break;

            case kMCLSettingsThreadViewFrame:
            default:
                storyboardIdentifier = @"MessageList2FrameStyleView";
                break;
        }
        self.detailViewController = [self.storyboard instantiateViewControllerWithIdentifier:storyboardIdentifier];

        UINavigationController *navController = [self.splitViewController.viewControllers lastObject];
        MCLMessageListViewController *oldController = [navController.viewControllers firstObject];
        [navController setViewControllers:[NSArray arrayWithObjects:self.detailViewController, nil]];
        UIBarButtonItem *splitViewButton = oldController.navigationItem.leftBarButtonItem;
        self.masterPopoverController = oldController.masterPopoverController;
        [self.detailViewController setSplitViewButton:splitViewButton forPopoverController:self.masterPopoverController];
    }

    // Cache original tables separatorColor and set to clear to avoid flickering loading view
    self.tableSeparatorColor = [self.tableView separatorColor];
    [self.tableView setSeparatorColor:[UIColor clearColor]];

    // Set title to board name
    self.title = self.board.name;

    if ( ! self.validLogin) {
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    // Init refresh control
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;

    // Visualize loading
    CGRect fullScreenFrame = [(MCLAppDelegate *)[[UIApplication sharedApplication] delegate] fullScreenFrameFromViewController:self];
    [self.view addSubview:[[MCLLoadingView alloc] initWithFrame:fullScreenFrame]];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    // Load data async
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *mServiceError;
        NSDictionary *data = [[MCLMServiceConnector sharedConnector] threadsFromBoardId:self.board.boardId error:&mServiceError];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self fetchedData:data error:mServiceError];
        });
    });
}

- (void)reloadData
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *mServiceError;
        NSDictionary *data = [[MCLMServiceConnector sharedConnector] threadsFromBoardId:self.board.boardId error:&mServiceError];
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
        CGRect fullScreenFrame = [(MCLAppDelegate *)[[UIApplication sharedApplication] delegate] fullScreenFrameFromViewController:self];
        switch (error.code) {
            case -2:
                [self.view addSubview:[[MCLInternetConnectionErrorView alloc] initWithFrame:fullScreenFrame]];
                break;

            default:
                [self.view addSubview:[[MCLMServiceErrorView alloc] initWithFrame:fullScreenFrame andText:[error localizedDescription]]];
                break;
        }
    } else {
        self.threads = [NSMutableArray array];        
        for (id object in data) {
            [self.threads addObject:[self threadFromJSON:object]];
        }

        // Restore tables separatorColor
        [self.tableView setSeparatorColor:self.tableSeparatorColor];

        [self.tableView reloadData];

        // Hide search bar behind navigation bar
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

- (MCLThread *)threadFromJSON:(id)object
{
    NSNumber *threadId = [object objectForKey:@"id"];
    NSNumber *messageId = [object objectForKey:@"messageId"];
    BOOL sticky = [[object objectForKey:@"sticky"] boolValue];
    BOOL closed = [[object objectForKey:@"closed"] boolValue];
    BOOL mod = [[object objectForKey:@"mod"] boolValue];
    NSString *username = [object objectForKey:@"username"];
    NSString *subject = [object objectForKey:@"subject"];
    NSDate *date = [self.dateFormatterForInput dateFromString:[object objectForKey:@"date"]];
    NSNumber *answerCount = [object objectForKey:@"answerCount"];
    NSDate *answerDate = [self.dateFormatterForInput dateFromString:[object objectForKey:@"answerDate"]];

    return  [MCLThread threadWithId:threadId
                          messageId:messageId
                             sticky:sticky
                             closed:closed
                                mod:mod
                           username:username
                            subject:subject
                               date:date
                        answerCount:answerCount
                         answerDate:answerDate];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Dispose of any resources that can be recreated.
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count;
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        count = [self.searchResults count];
    } else {
        count = [self.threads count];
    }
    
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MCLThread *thread = nil;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        thread = self.searchResults[indexPath.row];
    } else {
        thread = self.threads[indexPath.row];
    }

    static NSString *cellIdentifier = @"ThreadCell";
    MCLThreadTableViewCell *cell = (MCLThreadTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    cell.threadSubjectLabel.text = thread.subject;
    CGFloat subjectSize = cell.threadSubjectLabel.font.pointSize;
    cell.threadSubjectLabel.font = thread.isSticky ? [UIFont boldSystemFontOfSize:subjectSize] : [UIFont systemFontOfSize:subjectSize];
    
    cell.threadUsernameLabel.text = thread.username;
    
    if ([thread.username isEqualToString:self.username]) {
        cell.threadUsernameLabel.textColor = [UIColor blueColor];
    } else if (thread.isMod) {
        cell.threadUsernameLabel.textColor = [UIColor redColor];
    } else {
        cell.threadUsernameLabel.textColor = [UIColor blackColor];
    }
    
    [cell.threadUsernameLabel sizeToFit];
    
    cell.threadDateLabel.text = [NSString stringWithFormat:@" - %@", [self.dateFormatterForOutput stringFromDate:thread.date]];
    [cell.threadDateLabel sizeToFit];
    
    // Place dateLabel after authorLabel
    CGRect dateLabelFrame = cell.threadDateLabel.frame;
    dateLabelFrame.origin = CGPointMake(cell.threadUsernameLabel.frame.origin.x + cell.threadUsernameLabel.frame.size.width, dateLabelFrame.origin.y);
    cell.threadDateLabel.frame = dateLabelFrame;
    
    if ([self.readList messageIdIsRead:thread.messageId] || thread.isClosed) {
        [cell markRead];
    } else {
        [cell markUnread];
    }

    if (thread.isClosed) {
        [cell.threadIsClosedImageView setHidden:NO];
    } else {
        [cell.threadIsClosedImageView setHidden:YES];
    }

    cell.badgeString = [thread.answerCount stringValue];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.tableView rowHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MCLThread *thread = nil;
    MCLThreadTableViewCell *cell = nil;
    if (self.searchDisplayController.active) {
        thread = self.searchResults[indexPath.row];
        cell = (MCLThreadTableViewCell*)[self.searchDisplayController.searchResultsTableView cellForRowAtIndexPath:indexPath];
    } else {
        thread = self.threads[indexPath.row];
        cell = (MCLThreadTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    }

    [cell markRead];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        // Hide popoverController in portrait mode
        if ( ! UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])) {
            [self.masterPopoverController dismissPopoverAnimated:YES];
        }

        [self.detailViewController loadThread:thread fromBoard:self.board];
    } else {
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


#pragma mark - MCLComposeMessageViewControllerDelegate

- (void)composeMessageViewControllerDidFinish:(MCLComposeMessageViewController *)inController withType:(NSUInteger)type
{
    [self reloadData];
}


#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    self.searchResults = [NSMutableArray array];

    NSError *mServiceError;
    NSDictionary *data = [[MCLMServiceConnector sharedConnector] searchThreadsOnBoard:self.board.boardId withPhrase:searchBar.text error:&mServiceError];
   
    for (id object in data) {
        [self.searchResults addObject:[self threadFromJSON:object]];
    }
    
    [self.searchDisplayController.searchResultsTableView reloadData];
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"PushToMessageListWidmannStyle"] || [segue.identifier isEqualToString:@"PushToMessageListFrameStyle"]) {
        NSIndexPath *indexPath;
        MCLThread *thread;

        if (self.searchDisplayController.active) {
            indexPath = [self.searchDisplayController.searchResultsTableView indexPathForSelectedRow];
            thread = self.searchResults[indexPath.row];
        } else {
            indexPath = [self.tableView indexPathForSelectedRow];
            thread = self.threads[indexPath.row];
        }

        MCLMessageListFrameStyleViewController *destinationViewController;
        if ([segue.destinationViewController isKindOfClass:[UINavigationController class]]) {
            destinationViewController = (MCLMessageListFrameStyleViewController *)[[segue.destinationViewController viewControllers] objectAtIndex:0];
        } else {
            destinationViewController = segue.destinationViewController;
        }

        [destinationViewController setBoard:self.board];
        [destinationViewController setThread:thread];
    } else if ([segue.identifier isEqualToString:@"ModalToComposeThread"]) {
        MCLComposeMessageViewController *destinationViewController = ((MCLComposeMessageViewController *)[[segue.destinationViewController viewControllers] objectAtIndex:0]);
        [destinationViewController setDelegate:self];
        [destinationViewController setType:kMCLComposeTypeThread];
        [destinationViewController setBoardId:self.board.boardId];
    }
}

@end

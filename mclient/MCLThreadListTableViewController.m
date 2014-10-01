//
//  MCLThreadListTableViewController.m
//  mclient
//
//  Created by Christopher Reitz on 25.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "constants.h"
#import "KeychainItemWrapper.h"
#import "MCLMServiceConnector.h"
#import "MCLThreadListTableViewController.h"
#import "MCLMessageListWidmannStyleViewController.h" //TODO
#import "MCLMessageListFrameStyleViewController.h" //TODO
#import "MCLMessageListViewController.h"
#import "MCLErrorView.h"
#import "MCLLoadingView.h"
#import "MCLThreadTableViewCell.h"
#import "MCLThread.h"
#import "MCLBoard.h"
#import "MCLReadList.h"


@interface MCLThreadListTableViewController ()

@property (strong, nonatomic) UIColor *tableSeparatorColor;
@property (assign, nonatomic) CGRect tableViewBounds;
@property (strong, nonatomic) MCLMessageListViewController *detailViewController;
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (strong, nonatomic) NSMutableArray *threads;
@property (strong, nonatomic) NSMutableArray *searchResults;
@property (strong, nonatomic) MCLReadList *readList;
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

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
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDoesRelativeDateFormatting:YES];
    [self.dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [self.dateFormatter setTimeStyle:NSDateFormatterShortStyle];
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
            case kMCLSettingsThreadViewDefault:
            default:
                storyboardIdentifier = @"MessageListView";
                break;

            case kMCLSettingsThreadViewFrame:
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
    
    // Init refresh control
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;

    self.tableViewBounds = self.view.bounds;

    // Visualize loading
    [self.view addSubview:[[MCLLoadingView alloc] initWithFrame:self.tableViewBounds]];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    // Load data async
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [self loadData];
        [self performSelectorOnMainThread:@selector(fetchedData:) withObject:data waitUntilDone:YES];
    });
}

- (NSData *)loadData
{
    NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/threadlist", kMServiceBaseURL, self.board.boardId];
    NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString: urlString]];

    return data;
}

- (void)reloadData
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [self loadData];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self fetchedData:data];
            [self.refreshControl endRefreshing];
        });
    });
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
        self.threads = [NSMutableArray array];
        
        NSError *error;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        for (id object in json) {
            [self.threads addObject:[self threadFromJSON:object]];
        }

        for (id subview in self.view.subviews) {
            if ([[subview class] isSubclassOfClass: [MCLErrorView class]]) {
                [subview removeFromSuperview];
            } else if ([[subview class] isSubclassOfClass: [MCLLoadingView class]]) {
                [subview removeFromSuperview];
            }
        }
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

        // Restore tables separatorColor
        [self.tableView setSeparatorColor:self.tableSeparatorColor];

        [self.tableView reloadData];

        // Hide search bar behind navigation bar
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

- (MCLThread *)threadFromJSON:(id)object
{
    //TODO move this outside
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    
    NSNumber *threadId = [object objectForKey:@"id"];
    NSNumber *messageId = [object objectForKey:@"messageId"];
    BOOL sticky = [[object objectForKey:@"sticky"] boolValue];
    BOOL closed = [[object objectForKey:@"closed"] boolValue];
    BOOL mod = [[object objectForKey:@"mod"] boolValue];
    NSString *author = [object objectForKey:@"author"];
    NSString *subject = [object objectForKey:@"subject"];
    NSDate *date = [dateFormatter dateFromString:[object objectForKey:@"date"]];
    NSNumber *answerCount = [object objectForKey:@"answerCount"];
    NSDate *answerDate = [dateFormatter dateFromString:[object objectForKey:@"answerDate"]];

    return  [MCLThread threadWithId:threadId
                          messageId:messageId
                             sticky:sticky
                             closed:closed
                                mod:mod
                           username:author
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
    
    cell.threadDateLabel.text = [NSString stringWithFormat:@" - %@", [self.dateFormatter stringFromDate:thread.date]];
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
            case kMCLSettingsThreadViewDefault:
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

- (void)composeMessageViewControllerDidFinish:(MCLComposeMessageViewController *)inController
{
    [self.tableView reloadData];
}


#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    self.searchResults = [NSMutableArray array];
    
    MCLMServiceConnector *mServiceConnector = [[MCLMServiceConnector alloc] init];
    NSError *mServiceError;
    NSData *responseData = [mServiceConnector searchOnBoard:self.board.boardId withPhrase:searchBar.text error:&mServiceError];
   
    NSError *jsonError;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&jsonError];
    for (id object in json) {
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
        [destinationViewController setType:kComposeTypeThread];
        [destinationViewController setBoardId:self.board.boardId];
    }
}

@end

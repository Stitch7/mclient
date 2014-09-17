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
#import "MCLMessageListTableViewController.h"
#import "MCLComposeMessageTableViewController.h"
#import "MCLErrorView.h"
#import "MCLLoadingView.h"
#import "MCLThreadTableViewCell.h"
#import "MCLThread.h"
#import "MCLBoard.h"
#import "MCLReadList.h"


@interface MCLThreadListTableViewController ()

@property (assign, nonatomic) UIColor *tableSeparatorColor;
@property (assign, nonatomic) CGRect tableViewBounds;
@property (strong) NSMutableArray *threads;
@property (strong) NSMutableArray *searchResults;
@property (strong) MCLReadList *readList;
@property (strong) NSString *username;
@property (strong) NSDateFormatter *dateFormatter;

@end

@implementation MCLThreadListTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    if (self = [super initWithStyle:style]) {
        // Custom initialization
    }
    
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.readList = [[MCLReadList alloc] init];
    
    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:identifier accessGroup:nil];
    self.username = [keychainItem objectForKey:(__bridge id)(kSecAttrAccount)];
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDoesRelativeDateFormatting:YES];
    [self.dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [self.dateFormatter setTimeStyle:NSDateFormatterShortStyle];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Cache original tables separatorColor and set to clear to avoid flickering loading view
    self.tableSeparatorColor = [self.tableView separatorColor];
    [self.tableView setSeparatorColor:[UIColor clearColor]];

    // Set title to board name
    self.title = self.board.name;
    
    // Init refresh control
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to refresh..."];
    [refreshControl addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;

    self.tableViewBounds = self.view.bounds;

    // Add loading view
    [self.view addSubview:[[MCLLoadingView alloc] initWithFrame:self.tableViewBounds]];

    // Load data async
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [self loadData];
        [self performSelectorOnMainThread:@selector(fetchedData:) withObject:data waitUntilDone:YES];

//        // Remove loading view on main thread
//        dispatch_async(dispatch_get_main_queue(), ^{
//            for (id subview in self.view.subviews) {
//                if ([[subview class] isSubclassOfClass: [MCLLoadingView class]]) {
//                    [subview removeFromSuperview];
//                }
//            }
//            // Restore tables separatorColor
//            [self.tableView setSeparatorColor:tableSeparatorColor];
//        });
    });
}

- (void)stopRefresh
{
    [self.refreshControl endRefreshing];
}

- (NSData *)loadData
{
    NSString *urlString = [kMServiceBaseURL stringByAppendingString:[NSString stringWithFormat:@"board/%@/threadlist", self.board.boardId]];
    NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString: urlString]];

    return data;
}

- (void)reloadData
{
    NSData *data = [self loadData];
    [self fetchedData:data];
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

        // Restore tables separatorColor
        [self.tableView setSeparatorColor:self.tableSeparatorColor];

        [self.tableView reloadData];
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
    int answerCount = [[object objectForKey:@"answerCount"] integerValue];
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

    static NSString *CellIdentifier = @"ThreadCell";
    MCLThreadTableViewCell *cell = (MCLThreadTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    cell.threadSubjectLabel.text = thread.subject;
    float subjectSize = cell.threadSubjectLabel.font.pointSize;
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
    
    if ([self.readList messageIdIsRead:thread.messageId]) {
        [cell markRead];
    } else {
        [cell markUnread];
    }
    
    cell.badgeString = [@(thread.answerCount) stringValue];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = @"PushToMessageList";
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"frameStyle"]) {
        identifier = @"PushToMessageList2FrameStyle";
    }

    [self performSegueWithIdentifier:identifier sender:[self.tableView cellForRowAtIndexPath:indexPath]];
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


#pragma mark - Seque

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"PushToMessageList"] || [segue.identifier isEqualToString:@"PushToMessageList2FrameStyle"]) {
        NSIndexPath *indexPath = nil;
        MCLThread *thread = nil;
        MCLThreadTableViewCell *cell = nil;
        if (self.searchDisplayController.active) {
            indexPath = [self.searchDisplayController.searchResultsTableView indexPathForSelectedRow];
            thread = self.searchResults[indexPath.row];
            cell = (MCLThreadTableViewCell*)[self.searchDisplayController.searchResultsTableView cellForRowAtIndexPath:indexPath];
        } else {
            indexPath = [self.tableView indexPathForSelectedRow];
            thread = self.threads[indexPath.row];
            cell = (MCLThreadTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        }
        
        [self.readList addMessageId:thread.messageId];        
        [cell markRead];

        [segue.destinationViewController setBoard:self.board];
        [segue.destinationViewController setThread:thread];
    } else if ([segue.identifier isEqualToString:@"ModalToComposeThread"]) {
        MCLComposeMessageTableViewController *destinationViewController = ((MCLComposeMessageTableViewController *)[[segue.destinationViewController viewControllers] objectAtIndex:0]);
        [destinationViewController setType:kComposeTypeThread];
        [destinationViewController setBoardId:self.board.boardId];
    }
}

@end

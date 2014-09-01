//
//  MCLThreadListTableViewController.m
//  mclient
//
//  Created by Christopher Reitz on 25.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "constants.h"
#import "MCLThreadListTableViewController.h"
#import "MCLMessageListTableViewController.h"
#import "MCLThreadTableViewCell.h"
#import "MCLThread.h"
#import "MCLBoard.h"
#import "MCLReadList.h"


@interface MCLThreadListTableViewController ()

@property (strong) NSMutableArray *threads;
@property (strong) MCLReadList *readList;
@property (weak, nonatomic) NSUserDefaults *userDefaults;

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
    self.userDefaults = [NSUserDefaults standardUserDefaults];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.board.name;
    
    // Init refresh control
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to refresh..."];
    [refreshControl addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self performSelectorOnMainThread:@selector(fetchedData:) withObject:[self loadData] waitUntilDone:YES];
    });
    
   
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)stopRefresh
{
    [self.refreshControl endRefreshing];
}

- (NSData *)loadData
{
    NSString *urlString = [kMServiceBaseURL stringByAppendingString:[NSString stringWithFormat:@"threadlist/%i", self.board.id]];
    
    NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString: urlString]];
    [self performSelectorOnMainThread:@selector(fetchedData:) withObject:data waitUntilDone:YES];
    
    return data;
}

- (void)reloadData
{
    [self loadData];
    [self performSelector:@selector(stopRefresh) withObject:nil afterDelay:1.5]; // 2.5
}


- (void)fetchedData:(NSData *)responseData
{
    self.threads = [NSMutableArray array];
    
    NSError* error;
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
    for (id object in json) {
        NSNumber *threadId = [object objectForKey:@"id"];
        NSNumber *messageId = [object objectForKey:@"messageId"];
        BOOL sticky = [[object objectForKey:@"sticky"] boolValue];
        BOOL closed = [[object objectForKey:@"closed"] boolValue];
        BOOL mod = [[object objectForKey:@"mod"] boolValue];
        NSString *author = [object objectForKey:@"author"];
        NSString *subject = [object objectForKey:@"subject"];
        NSString *date = [object objectForKey:@"date"];
        int answerCount = [[object objectForKey:@"answerCount"] integerValue];
        NSString *answerDate = [object objectForKey:@"answerDate"];
        
        MCLThread *thread = [MCLThread threadWithId:threadId
                                          messageId:messageId
                                             sticky:sticky
                                             closed:closed
                                                mod:mod
                                             author:author
                                            subject:subject
                                               date:date
                                        answerCount:answerCount
                                         answerDate:answerDate];
        
        [self.threads addObject:thread];
    }
    
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Dispose of any resources that can be recreated.
}


#pragma mark - UIWebViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.threads count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    NSLog(@"cellForRowAtIndexPath: %i", indexPath.row);
    
    MCLThread *thread = self.threads[indexPath.row];
    MCLThreadTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ThreadCell" forIndexPath:indexPath];
        
    cell.threadSubjectLabel.text = thread.subject;
    float subjectSize = cell.threadSubjectLabel.font.pointSize;
    cell.threadSubjectLabel.font = thread.isSticky ? [UIFont boldSystemFontOfSize:subjectSize] : [UIFont systemFontOfSize:subjectSize];
    
    cell.threadAuthorLabel.text = thread.author;
    
    if ([thread.author isEqualToString:[self.userDefaults objectForKey:@"username"]]) {
//        cell.threadAuthorLabel.textColor = [UIColor colorWithRed:0 green:0.478 blue:1 alpha:1.0]; //TODO make const
        cell.threadAuthorLabel.textColor = [UIColor blueColor]; //TODO make const
    } else if (thread.isMod) {
        cell.threadAuthorLabel.textColor = [UIColor redColor];
    } else {
        cell.threadAuthorLabel.textColor = [UIColor blackColor];
    }
    
    [cell.threadAuthorLabel sizeToFit];
    
    cell.threadDateLabel.text = [NSString stringWithFormat:@" - %@", thread.date];
    [cell.threadDateLabel sizeToFit];
    
    // Place dateLabel after authorLabel
    CGRect dateLabelFrame = cell.threadDateLabel.frame;
    dateLabelFrame.origin = CGPointMake(cell.threadAuthorLabel.frame.origin.x + cell.threadAuthorLabel.frame.size.width, dateLabelFrame.origin.y);
    cell.threadDateLabel.frame = dateLabelFrame;
    
    if ([self.readList messageIdIsRead:thread.messageId]) {
        [cell markRead];
    } else {
        [cell markUnread];
    }
    
    cell.badgeString = [@(thread.answerCount) stringValue];
    
    return cell;
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"PushToMessageList"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        
        MCLThread *thread = self.threads[indexPath.row];
        [self.readList addMessageId:thread.messageId];
        
        MCLThreadTableViewCell *cell = (MCLThreadTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        [cell markRead];
        
        [segue.destinationViewController setThread:thread];
    }    
}


@end

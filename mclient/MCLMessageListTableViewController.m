//
//  MCLMessageListTableViewController.m
//  mclient
//
//  Created by Christopher Reitz on 25.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "constants.h"
#import "MCLMessageListTableViewController.h"
#import "MCLThread.h"
#import "MCLMessage.h"
#import "MCLMessageTableViewCell.h"

@interface MCLMessageListTableViewController ()

@property (strong) NSMutableArray *messages;

@end

@implementation MCLMessageListTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.messages = [NSMutableArray array];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.thread.subject;
    
    // Init refresh control
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to refresh..."];
    [refreshControl addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self performSelectorOnMainThread:@selector(fetchedData:) withObject:[self loadData] waitUntilDone:YES];
    });
    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        NSString *urlString = [kMServiceBaseURL stringByAppendingString:[NSString stringWithFormat:@"thread/%i", self.thread.id]];
//        
//        NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString: urlString]];
//        [self performSelectorOnMainThread:@selector(fetchedData:) withObject:data waitUntilDone:YES];
//    });
    
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
    NSString *urlString = [kMServiceBaseURL stringByAppendingString:[NSString stringWithFormat:@"thread/%i", self.thread.id]];
    
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
    NSError* error;
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
    for (id object in json) {
        int messageId = [[object objectForKey:@"id"] integerValue];
        int level = [[object objectForKey:@"level"] integerValue];
        NSString *author = [object objectForKey:@"author"];
        NSString *subject = [object objectForKey:@"subject"];
        NSString *date = [object objectForKey:@"date"];
        NSString *text = [object objectForKey:@"text"];
        
        MCLMessage *message = [MCLMessage messageWithId:messageId level:level author:author subject:subject date:date text:text];
        [self.messages addObject:message];
    }
    
    [self.tableView reloadData];
}

- (NSString*)loadMessageText:(int)messageId
{
    NSString *urlString = [kMServiceBaseURL stringByAppendingString:[NSString stringWithFormat:@"message/%i", messageId]];
    
    NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString: urlString]];
    
    NSError* error;
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    
    NSString *messageText = [json objectForKey:@"text"];
    
    return messageText;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.messages count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MCLMessage *message = self.messages[indexPath.row];
    MCLMessageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MessageCell" forIndexPath:indexPath];
    
    // Configure the cell...
    cell.messageSubjectLabel.text = message.subject;
    cell.messageAuthorLabel.text = message.author;
    cell.messageDateLabel.text = [NSString stringWithFormat:@" - %@", message.date];
    
    //cell.imageView
    
    [cell.messageAuthorLabel sizeToFit];
    [cell.messageDateLabel sizeToFit];
    
    // Place dateLabel after authorLabel
    CGRect dateLabelFrame = cell.messageDateLabel.frame;
    dateLabelFrame.origin = CGPointMake(cell.messageAuthorLabel.frame.origin.x + cell.messageAuthorLabel.frame.size.width, dateLabelFrame.origin.y);
    cell.messageDateLabel.frame = dateLabelFrame;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([tableView indexPathsForSelectedRows].count) {
        
		if ([[tableView indexPathsForSelectedRows] indexOfObject:indexPath] != NSNotFound) {
			return 120; // Expanded height
		}
        
        return 60; // Normal height
	}
    
    return 60; // Normal height
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    [self updateTableView];
    
    MCLMessage *message = self.messages[indexPath.row];
//    MCLMessageTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    [self.tableView beginUpdates];


    if (!message.text) {
        NSLog(@"Loading Message ID: %i", message.id);
        message.text = [self loadMessageText:message.id];        
    }
    NSLog(@"%@", message.text);
    
    
    
    [self.tableView endUpdates];
    
    
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self updateTableView];
}

- (void)updateTableView
{
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}



/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

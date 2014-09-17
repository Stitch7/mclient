//
//  MCLThreadListTableViewController.h
//  mclient
//
//  Created by Christopher Reitz on 25.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MCLMessageListTableViewController;
@class MCLBoard;

@interface MCLThreadListTableViewController : UITableViewController <UISearchBarDelegate>

@property (strong, nonatomic) MCLMessageListTableViewController *messageListTableViewController;

@property (strong, nonatomic) MCLBoard *board;

@end

//
//  MCLMessageListTableViewController.h
//  mclient
//
//  Created by Christopher Reitz on 25.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MCLMessageListViewController.h"
#import "MCLComposeMessageViewController.h"

@class MCLBoard;
@class MCLThread;

@interface MCLMessageListWidmannStyleViewController : MCLMessageListViewController <UITableViewDelegate, UITableViewDataSource, UIWebViewDelegate, MCLComposeMessageViewControllerDelegate>

@property (strong, nonatomic) MCLBoard *board;
@property (strong, nonatomic) MCLThread *thread;

- (void)loadThread:(MCLThread *)inThread fromBoard:(MCLBoard *)inBoard;

@end

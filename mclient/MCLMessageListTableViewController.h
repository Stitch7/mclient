//
//  MCLMessageListTableViewController.h
//  mclient
//
//  Created by Christopher Reitz on 25.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MCLThread;

@interface MCLMessageListTableViewController : UITableViewController

@property (strong) MCLThread *thread;

@end

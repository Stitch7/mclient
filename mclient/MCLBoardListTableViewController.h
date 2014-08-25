//
//  MCLBoardListTableViewController.h
//  mclient
//
//  Created by Christopher Reitz on 21.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MCLMessageViewController;

@interface MCLBoardListTableViewController : UITableViewController

@property (strong, nonatomic) MCLMessageViewController *detailViewController;

@end

//
//  MCLBoardListTableViewController.h
//  mclient
//
//  Created by Christopher Reitz on 21.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MCLBoard;

@interface MCLBoardListTableViewController : UITableViewController <UISplitViewControllerDelegate>

@property (strong) MCLBoard *preselectedBoard;

@end

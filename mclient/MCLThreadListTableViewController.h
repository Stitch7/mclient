//
//  MCLThreadListTableViewController.h
//  mclient
//
//  Created by Christopher Reitz on 25.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MCLComposeMessageViewController.h"

@class MCLBoard;

@interface MCLThreadListTableViewController : UITableViewController <MCLComposeMessageViewControllerDelegate, UISearchControllerDelegate, UISearchResultsUpdating>

@property (strong, nonatomic) MCLBoard *board;

@end

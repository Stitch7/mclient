//
//  MCLMessageListTableViewController.h
//  mclient
//
//  Created by Christopher Reitz on 25.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MCLMessageListViewController.h"
#import "MCLProfileTableViewController.h"
#import "MCLComposeMessageViewController.h"

@interface MCLMessageListWidmannStyleViewController : MCLMessageListViewController <MCLProfileTableViewControllerDelegate, MCLComposeMessageViewControllerDelegate, UITableViewDelegate, UITableViewDataSource, UIWebViewDelegate>

@end

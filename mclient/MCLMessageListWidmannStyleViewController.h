//
//  MCLMessageListWidmannStyleViewController.h
//  mclient
//
//  Created by Christopher Reitz on 25.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "MCLMessageListViewController.h"
#import "MCLMessageListWidmannStyleTableViewCell.h"
#import "MCLProfileTableViewController.h"
#import "MCLComposeMessageViewController.h"

@interface MCLMessageListWidmannStyleViewController : MCLMessageListViewController <MCLMessageListWidmannStyleTableViewCellDelegate, MCLProfileTableViewControllerDelegate, MCLComposeMessageViewControllerDelegate, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, WKNavigationDelegate>

@end

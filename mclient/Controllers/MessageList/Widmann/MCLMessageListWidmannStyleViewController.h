//
//  MCLMessageListWidmannStyleViewController.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@import WebKit;

#import "MCLMessageListViewController.h"
#import "MCLMessageListWidmannStyleTableViewCell.h"
#import "MCLProfileTableViewController.h"

@interface MCLMessageListWidmannStyleViewController : MCLMessageListViewController <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, WKNavigationDelegate, MCLMessageListWidmannStyleTableViewCellDelegate>

@end

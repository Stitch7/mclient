//
//  MCLProfileTableViewController.h
//  mclient
//
//  Created by Christopher Reitz on 06.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MCLProfileTableViewControllerDelegate;

@interface MCLProfileTableViewController : UITableViewController

@property (weak) id<MCLProfileTableViewControllerDelegate> delegate;
@property (strong, nonatomic) NSNumber *userId;
@property (strong, nonatomic) NSString *username;

@end

@protocol MCLProfileTableViewControllerDelegate <NSObject>

@optional
- (void)handleRotationChangeInBackground;

@end
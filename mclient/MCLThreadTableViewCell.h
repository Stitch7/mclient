//
//  MCLThreadTableViewCell.h
//  mclient
//
//  Created by Christopher Reitz on 26.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MCLReadSymbolView;
@class MCLBadgeView;
@class MCLReadList;
@class MCLThread;

@interface MCLThreadTableViewCell : UITableViewCell

@property (strong, nonatomic) MCLThread *thread;
@property (weak, nonatomic) IBOutlet MCLReadSymbolView *readSymbolView;
@property (weak, nonatomic) IBOutlet UIImageView *threadIsStickyImageView;
@property (weak, nonatomic) IBOutlet UIImageView *threadIsClosedImageView;
@property (weak, nonatomic) IBOutlet UILabel *threadSubjectLabel;
@property (weak, nonatomic) IBOutlet UILabel *threadUsernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *threadDateLabel;
@property (weak, nonatomic) IBOutlet MCLBadgeView *badgeView;
@property (weak, nonatomic) IBOutlet UILabel *badgeLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *readSymbolViewLeadingConstraint;

- (void)markRead;
- (void)markUnread;
- (void)updateBadge:(MCLReadList *)readList forThread:(MCLThread *)thread;

@end

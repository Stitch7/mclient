//
//  MCLThreadTableViewCell.h
//  mclient
//
//  Created by Christopher Reitz on 26.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MCLReadSymbolView;

@interface MCLThreadTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet MCLReadSymbolView *readSymbolView;
@property (weak, nonatomic) IBOutlet UIImageView *threadIsClosedImageView;
@property (weak, nonatomic) IBOutlet UILabel *threadSubjectLabel;
@property (weak, nonatomic) IBOutlet UILabel *threadUsernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *threadDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *badgeLabel;

- (void)markRead;
- (void)markUnread;

@end

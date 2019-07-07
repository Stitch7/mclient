//
//  MCLThreadTableViewCell.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MGSwipeTableCell.h"

@protocol MCLTheme;
@class MCLLoginManager;
@class MCLReadSymbolView;
@class MCLBadgeView;
@class MCLThread;

extern NSString *const MCLThreadTableViewCellIdentifier;

@interface MCLThreadTableViewCell : MGSwipeTableCell

@property (assign, nonatomic) NSInteger index;
@property (strong, nonatomic) MCLLoginManager *loginManager;
@property (strong, nonatomic) MCLThread *thread;
@property (strong, nonatomic) id <MCLTheme> currentTheme;
@property (assign, nonatomic, getter=isFavorite) BOOL favorite;
@property (weak, nonatomic) IBOutlet MCLReadSymbolView *readSymbolView;
@property (weak, nonatomic) IBOutlet UIImageView *threadIsStickyImageView;
@property (weak, nonatomic) IBOutlet UIImageView *threadIsFavoriteImageView;
@property (weak, nonatomic) IBOutlet UIImageView *threadIsClosedImageView;
@property (weak, nonatomic) IBOutlet UILabel *threadSubjectLabel;
@property (weak, nonatomic) IBOutlet UILabel *threadUsernameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *threadDateImageView;
@property (weak, nonatomic) IBOutlet UILabel *threadDateLabel;
@property (weak, nonatomic) IBOutlet MCLBadgeView *badgeView;
@property (weak, nonatomic) IBOutlet UILabel *badgeLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *readSymbolWidthConstraint;

- (void)markRead;
- (void)markUnread;
- (void)updateBadgeWithThread:(MCLThread *)thread andTheme:(id <MCLTheme>)theme;

@end

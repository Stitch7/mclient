//
//  MCLMessageListFrameStyleTableViewCell.h
//  mclient
//
//  Created by Christopher Reitz on 15/12/2016.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MCLReadSymbolView;

@interface MCLMessageListFrameStyleTableViewCell : UITableViewCell

@property (strong, nonatomic) NSNumber *boardId;
@property (strong, nonatomic) NSNumber *messageId;
@property (strong, nonatomic) NSString *messageText;
@property (assign, nonatomic) BOOL messageNotification;

@property (weak, nonatomic) IBOutlet MCLReadSymbolView *readSymbolView;
@property (weak, nonatomic) IBOutlet UIImageView *messageIndentionImageView;
@property (weak, nonatomic) IBOutlet UILabel *messageSubjectLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageUsernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageDateLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *indentionConstraint;

- (void)markRead;
- (void)markUnread;

@end

//
//  MCLMessageListFrameStyleTableViewCell.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@class MCLMessage;
@class MCLReadSymbolView;

extern NSString *const MCLMessageListFrameStyleTableViewCellIdentifier;

@interface MCLMessageListFrameStyleTableViewCell : UITableViewCell

@property (strong, nonatomic) MCLMessage *message;
@property (strong, nonatomic) NSNumber *boardId;
@property (strong, nonatomic) NSNumber *messageId;
@property (strong, nonatomic) NSString *messageText;
@property (assign, nonatomic) BOOL messageNotification;

@property (weak, nonatomic) IBOutlet MCLReadSymbolView *readSymbolView;
@property (weak, nonatomic) IBOutlet UIView *messageIndentionView;
@property (weak, nonatomic) IBOutlet UIImageView *messageIndentionImageView;
@property (weak, nonatomic) IBOutlet UILabel *messageSubjectLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageUsernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageDateLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *indentionConstraint;

- (void)markRead;
- (void)markUnread;

@end

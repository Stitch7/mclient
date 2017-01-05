//
//  MCLMessageListWidmannStyleTableViewCell.h
//  mclient
//
//  Created by Christopher Reitz on 30/12/2016.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@protocol MCLMessageListWidmannStyleTableViewCellDelegate;

@class MCLReadSymbolView;

@interface MCLMessageListWidmannStyleTableViewCell : UITableViewCell <AVSpeechSynthesizerDelegate>

@property (weak) id<MCLMessageListWidmannStyleTableViewCellDelegate> delegate;

@property (strong, nonatomic) NSNumber *boardId;
@property (strong, nonatomic) NSNumber *messageId;
@property (strong, nonatomic) NSString *messageText;
@property (assign, nonatomic) BOOL messageNotification;

@property (strong, nonatomic) UIImageView *messageIndentionImageView;
@property (strong, nonatomic) NSLayoutConstraint *messageIndentionConstraint;
@property (strong, nonatomic) UILabel *messageSubjectLabel;
@property (strong, nonatomic) UILabel *messageUsernameLabel;
@property (strong, nonatomic) UILabel *messageDateLabel;
@property (strong, nonatomic) WKWebView *messageTextWebView;
@property (strong, nonatomic) NSLayoutConstraint *messageTextWebViewHeightConstraint;

@property (strong, nonatomic) MCLReadSymbolView *readSymbolView;
@property (strong, nonatomic) UIToolbar *messageToolbar;
@property (strong, nonatomic) UIBarButtonItem *messageProfileButton;
@property (strong, nonatomic) UIBarButtonItem *messageSpeakButton;
@property (strong, nonatomic) UIBarButtonItem *messageNotificationButton;
@property (strong, nonatomic) UIBarButtonItem *messageEditButton;
@property (strong, nonatomic) UIBarButtonItem *messageReplyButton;

@property (strong, nonatomic) AVSpeechSynthesizer *speechSynthesizer;

- (void)markRead;
- (void)markUnread;
- (void)enableNotificationButton:(BOOL)enable;

@end

@protocol MCLMessageListWidmannStyleTableViewCellDelegate <NSObject>

@optional
- (void)openProfileButtonPressed;
- (void)editButtonPressed;
- (void)replyButtonPressed;

@end

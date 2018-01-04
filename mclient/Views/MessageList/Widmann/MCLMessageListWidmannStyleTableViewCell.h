//
//  MCLMessageListWidmannStyleTableViewCell.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@import WebKit;

@protocol MCLMessageListWidmannStyleTableViewCellDelegate;
@protocol MCLTheme;

@class MCLLogin;
@class MCLMessage;
@class MCLReadSymbolView;
@class MCLMessageToolbar;

extern NSString *const MCLMessageListWidmannStyleTableViewCellIdentifier;

@interface MCLMessageListWidmannStyleTableViewCell : UITableViewCell <WKScriptMessageHandler>

@property (weak) id<MCLMessageListWidmannStyleTableViewCellDelegate> delegate;

@property (strong, nonatomic) MCLLogin *login;
@property (strong, nonatomic) id <MCLTheme> currentTheme;
@property (strong, nonatomic) MCLMessage *message;
@property (strong, nonatomic) MCLMessage *nextMessage;

@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSIndexPath *indexPath;
@property (assign, nonatomic, getter=isActive) BOOL active;
@property (strong, nonatomic) UIImageView *indentionImageView;
@property (strong, nonatomic) NSLayoutConstraint *indentionConstraint;
@property (strong, nonatomic) UILabel *subjectLabel;
@property (strong, nonatomic) UILabel *usernameLabel;
@property (strong, nonatomic) UILabel *dateLabel;
@property (strong, nonatomic) WKWebView *webView;
@property (strong, nonatomic) NSLayoutConstraint *webViewHeightConstraint;

@property (strong, nonatomic) MCLReadSymbolView *readSymbolView;
@property (strong, nonatomic) MCLMessageToolbar *toolbar;

- (void)markRead;
- (void)markUnread;
- (void)contentHeightWithCompletion:(void (^)(CGFloat height))completionHandler;

@end

@protocol MCLMessageListWidmannStyleTableViewCellDelegate <NSObject>

- (void)contentChanged;

@end


//
//  MCLMessageToolbar.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLMessageToolbarDelegate;

@class MCLMessage;
@class MCLLoginManager;
@class MCLMessageListWidmannStyleTableViewCell;

@interface MCLMessageToolbar : UIToolbar

@property (strong) id<MCLMessageToolbarDelegate> messageToolbarDelegate; // TODO: weak?
@property (strong, nonatomic) MCLLoginManager *loginManager;
@property (strong, nonatomic) MCLMessage *message;
@property (strong, nonatomic) MCLMessage *nextMessage;

@property (strong, nonatomic) UIBarButtonItem *profileButton;
@property (strong, nonatomic) UIBarButtonItem *linkToClipboardButton;
@property (strong, nonatomic) UIBarButtonItem *speakButton;
@property (strong, nonatomic) UIBarButtonItem *notificationButton;
@property (strong, nonatomic) UIBarButtonItem *editButton;
@property (strong, nonatomic) UIBarButtonItem *replyButton;

- (void)enableNotificationButton:(BOOL)enable;
- (void)deactivateBarButtons;
- (void)updateBarButtonsWithMessage:(MCLMessage *)message;
- (void)updateBarButtons;
- (BOOL)notificationButtonIsVisible;
- (BOOL)editButtonIsVisible;
- (BOOL)replyButtonIsVisible;

- (void)openProfileAction:(UIBarButtonItem *)sender;
- (void)copyLinkAction:(UIBarButtonItem *)sender;
- (void)speakAction:(UIBarButtonItem *)sender;
- (void)notificationAction:(UIBarButtonItem *)sender;
- (void)editAction:(UIBarButtonItem *)sender;
- (void)replyAction:(UIBarButtonItem *)sender;

@end

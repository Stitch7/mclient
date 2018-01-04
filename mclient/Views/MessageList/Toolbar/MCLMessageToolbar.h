//
//  MCLMessageToolbar.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLMessageToolbarDelegate;

@class MCLMessage;
@class MCLLogin;
@class MCLMessageListWidmannStyleTableViewCell;

@interface MCLMessageToolbar : UIToolbar

@property (weak) id<MCLMessageToolbarDelegate> messageToolbarDelegate;
@property (strong, nonatomic) MCLLogin *login;
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

@end

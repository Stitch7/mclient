//
//  MCLMessageTableViewCell.h
//  mclient
//
//  Created by Christopher Reitz on 26.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class MCLReadSymbolView;

@interface MCLMessageTableViewCell : UITableViewCell <AVSpeechSynthesizerDelegate>

@property (strong, nonatomic) NSNumber *boardId;
@property (strong, nonatomic) NSNumber *messageId;
@property (strong, nonatomic) NSString *messageText;
@property (assign, nonatomic) BOOL messageNotification;

@property (weak, nonatomic) IBOutlet UILabel *messageSubjectLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageUsernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageDateLabel;
@property (weak, nonatomic) IBOutlet UIWebView *messageTextWebView;

@property (weak, nonatomic) IBOutlet MCLReadSymbolView *readSymbolView;
@property (weak, nonatomic) IBOutlet UIToolbar *messageToolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *messageProfileButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *messageSpeakButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *messageNotificationButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *messageEditButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *messageReplyButton;

@property (strong, nonatomic) AVSpeechSynthesizer *speechSynthesizer;

- (void)markRead;
- (void)markUnread;
- (void)enableNotificationButton:(BOOL)enable;

@end

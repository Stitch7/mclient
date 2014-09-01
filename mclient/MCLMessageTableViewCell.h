//
//  MCLMessageTableViewCell.h
//  mclient
//
//  Created by Christopher Reitz on 26.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MCLReadSymbolView;

@interface MCLMessageTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *messageSubjectLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageAuthorLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageDateLabel;
@property (weak, nonatomic) IBOutlet UIWebView *messageTextWebView;
@property (weak, nonatomic) NSString *messageText;
@property (weak, nonatomic) IBOutlet MCLReadSymbolView *readSymbolView;
@property (weak, nonatomic) IBOutlet UIToolbar *messageToolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *messageSpeakButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *messageReplyButton;

- (void)markRead;
- (void)markUnread;

@end

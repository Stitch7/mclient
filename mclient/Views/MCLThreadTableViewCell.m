//
//  MCLThreadTableViewCell.m
//  mclient
//
//  Created by Christopher Reitz on 26.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLThreadTableViewCell.h"
#import "MCLReadSymbolView.h"
#import "MCLBadgeView.h"
#import "MCLThread.h"
#import "MCLReadList.h"

@implementation MCLThreadTableViewCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (UIEdgeInsets)layoutMargins
{
    return UIEdgeInsetsZero;
}

- (void)markRead
{
    self.readSymbolView.hidden = YES;

    if (self.thread.isSticky) {
        self.threadSubjectLabel.font = [UIFont systemFontOfSize:15.0f weight:UIFontWeightBold];
    }
    else {
        self.threadSubjectLabel.font = [UIFont systemFontOfSize:15.0f];
    }
}

- (void)markUnread
{
    self.readSymbolView.hidden = NO;

    if (self.thread.isSticky) {
        self.threadSubjectLabel.font = [UIFont systemFontOfSize:15.0f weight:UIFontWeightBold];
    }
    else {
        self.threadSubjectLabel.font = [UIFont systemFontOfSize:15.0f weight:UIFontWeightSemibold];
    }
}

- (void)updateBadge:(MCLReadList *)readList forThread:(MCLThread *)thread
{
    self.badgeLabel.text = [thread.messageCount stringValue];

    int messageCount = [thread.messageCount intValue];
    int readMessagesCount = [[readList readMessagesCountFromThread:thread] intValue];
    BOOL isRead = [readList messageIdIsRead:thread.messageId fromThread:thread];

    if (messageCount > 999 && !thread.isSticky) {
        // red
        self.badgeLabel.textColor = [UIColor redColor];
    }
    else if (!isRead || readMessagesCount < messageCount) {
        // blue
        self.badgeLabel.textColor = [UIColor colorWithRed:0 green:0.478 blue:1 alpha:1.0];
    }
    else {
        // gray
        self.badgeLabel.textColor = [UIColor darkGrayColor];
    }
}

@end

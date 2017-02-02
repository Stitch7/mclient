//
//  MCLThreadTableViewCell.m
//  mclient
//
//  Created by Christopher Reitz on 26.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLThreadTableViewCell.h"

#import "MCLTheme.h"
#import "MCLReadSymbolView.h"
#import "MCLBadgeView.h"
#import "MCLThread.h"

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

- (void)updateBadgeWithThread:(MCLThread *)thread andTheme:(id <MCLTheme>)theme
{
    self.badgeLabel.text = [thread.messagesCount stringValue];

    if ([thread.messagesCount intValue] > 999 && !thread.isSticky) {
        // red
        self.badgeLabel.textColor = [theme warnTextColor];
    }
    else if (!thread.isRead || [thread.messagesRead intValue] < [thread.messagesCount intValue]) {
        // blue
        self.badgeLabel.textColor = [theme tintColor];
    }
    else {
        // gray
        self.badgeLabel.textColor = [UIColor darkGrayColor];
    }
}

@end

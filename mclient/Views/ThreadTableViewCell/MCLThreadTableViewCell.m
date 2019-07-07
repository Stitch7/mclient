//
//  MCLThreadTableViewCell.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLThreadTableViewCell.h"

#import "MCLTheme.h"
#import "MCLReadSymbolView.h"
#import "MCLBadgeView.h"
#import "MCLThread.h"
#import "MCLTheme.h"
#import "MCLThemeManager.h"
#import "MCLLoginManager.h"


NSString *const MCLThreadTableViewCellIdentifier = @"ThreadCell";

@implementation MCLThreadTableViewCell

- (UIEdgeInsets)layoutMargins
{
    return UIEdgeInsetsZero;
}

- (void)setFavorite:(BOOL)favorite
{
    self.threadIsFavoriteImageView.hidden = !favorite;
}

- (void)setThread:(MCLThread *)thread
{
    id <MCLTheme> theme = self.currentTheme;

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDoesRelativeDateFormatting:YES];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];

    self.separatorInset = UIEdgeInsetsZero;

    UIView *backgroundView = [[UIView alloc] initWithFrame:self.frame];
    backgroundView.backgroundColor = [theme tableViewCellSelectedBackgroundColor];
    self.selectedBackgroundView = backgroundView;

    self.threadSubjectLabel.text = thread.subject;

    self.threadUsernameLabel.text = thread.username;
    if (self.loginManager.isLoginValid && [thread.username isEqualToString:self.loginManager.username]) {
        self.threadUsernameLabel.textColor = [theme ownUsernameTextColor];
    } else if (thread.isMod) {
        self.threadUsernameLabel.textColor = [theme modTextColor];
    } else {
        self.threadUsernameLabel.textColor = [theme usernameTextColor];
    }

    self.threadDateImageView.image = [self.threadDateImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

    NSDate *threadDate = thread.lastMessageDate ? thread.lastMessageDate : thread.date;
    self.threadDateLabel.text = [dateFormatter stringFromDate:threadDate];
    self.threadDateLabel.textColor = [theme detailTextColor];

    if (thread.isRead || thread.isTemporaryRead || thread.isClosed) {
        [self markRead];
    } else {
        [self markUnread];
    }

    self.threadIsFavoriteImageView.hidden = !thread.isFavorite;
    self.threadIsFavoriteImageView.image = [self.threadIsFavoriteImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.threadIsFavoriteImageView.tintColor = [theme detailImageColor];

    self.threadIsStickyImageView.image = [self.threadIsStickyImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.threadIsStickyImageView.tintColor = [theme detailImageColor];
    [self.threadIsStickyImageView setHidden:!thread.isSticky];

    self.threadIsClosedImageView.image = [self.threadIsClosedImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.threadIsClosedImageView.tintColor = [theme detailImageColor];
    [self.threadIsClosedImageView setHidden:!thread.isClosed];

    self.badgeView.userInteractionEnabled = NO;
    self.badgeLabel.userInteractionEnabled = NO;

    [self updateBadgeWithThread:thread andTheme:theme];
}

- (void)markRead
{
    self.readSymbolWidthConstraint.constant = 0.0f;

    if (self.thread.isSticky) {
        self.threadSubjectLabel.font = [UIFont systemFontOfSize:15.0f weight:UIFontWeightBold];
    }
    else {
        self.threadSubjectLabel.font = [UIFont systemFontOfSize:15.0f];
    }
}

- (void)markUnread
{
    self.readSymbolWidthConstraint.constant = 8.0f;

    if (self.thread.isSticky) {
        self.threadSubjectLabel.font = [UIFont systemFontOfSize:15.0f weight:UIFontWeightBold];
    }
    else {
        self.threadSubjectLabel.font = [UIFont systemFontOfSize:15.0f weight:UIFontWeightSemibold];
    }
}

- (void)updateBadgeWithThread:(MCLThread *)thread andTheme:(id <MCLTheme>)theme
{
    self.threadDateImageView.tintColor = thread.lastMessageIsRead ? [theme detailTextColor] : [theme tintColor];
    self.badgeView.backgroundColor = [theme badgeViewBackgroundColor];
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

    [self setNeedsLayout];
    [self layoutIfNeeded];
}

@end

//
//  MCLMessageListFrameStyleTableViewCell.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLMessageListFrameStyleTableViewCell.h"
#import "MCLReadSymbolView.h"

NSString *const MCLMessageListFrameStyleTableViewCellIdentifier = @"FrameStyleMessageCell";

@implementation MCLMessageListFrameStyleTableViewCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)setMessage:(MCLMessage *)message
{
    
}

- (void)markRead
{
    self.readSymbolView.hidden = YES;
    self.messageSubjectLabel.font = [UIFont systemFontOfSize:15.0f];
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)markUnread
{
    self.readSymbolView.hidden = NO;
    self.messageSubjectLabel.font = [UIFont systemFontOfSize:15.0f weight:UIFontWeightSemibold];
}

@end

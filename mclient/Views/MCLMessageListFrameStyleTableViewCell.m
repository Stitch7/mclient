//
//  MCLMessageListFrameStyleTableViewCell.m
//  mclient
//
//  Created by Christopher Reitz on 15/12/2016.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

#import "MCLMessageListFrameStyleTableViewCell.h"
#import "MCLReadSymbolView.h"

@implementation MCLMessageListFrameStyleTableViewCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)markRead
{
    self.readSymbolView.hidden = YES;
    self.messageSubjectLabel.font = [UIFont systemFontOfSize:15.0f];
}

- (void)markUnread
{
    self.readSymbolView.hidden = NO;
    self.messageSubjectLabel.font = [UIFont systemFontOfSize:15.0f weight:UIFontWeightSemibold];
}

@end

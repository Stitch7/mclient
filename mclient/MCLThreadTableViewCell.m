//
//  MCLThreadTableViewCell.m
//  mclient
//
//  Created by Christopher Reitz on 26.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLThreadTableViewCell.h"
#import "MCLReadSymbolView.h"

@implementation MCLThreadTableViewCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)markRead
{
    self.readSymbolView.hidden = YES;
}

- (void)markUnread
{
    self.readSymbolView.hidden = NO;
}

@end

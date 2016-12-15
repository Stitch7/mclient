//
//  MCLBadgeView.m
//  mclient
//
//  Created by Christopher Reitz on 15/12/2016.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

#import "MCLBadgeView.h"

@implementation MCLBadgeView

- (id)initWithCoder:(NSCoder*)coder
{
    if (self = [super initWithCoder:coder]) {
        [self commonInit];
    }

    return self;
}

- (id)initWithFrame:(CGRect)rect
{
    if (self = [super initWithFrame:rect]) {
        [self commonInit];
    }

    return self;
}

- (void)commonInit
{
    self.backgroundColor = [UIColor colorWithRed:0 green:0.478 blue:1 alpha:1.0];
    self.backgroundColor = [UIColor lightGrayColor];
    self.backgroundColor = [UIColor colorWithRed:0.92 green:0.94 blue:0.95 alpha:1.0];
    self.layer.cornerRadius = 3;
    self.layer.masksToBounds = YES;
}

@end

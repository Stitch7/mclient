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
    self.layer.cornerRadius = 3;
    self.layer.masksToBounds = YES;
}

@end

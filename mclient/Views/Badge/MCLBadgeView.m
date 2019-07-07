//
//  MCLBadgeView.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLBadgeView.h"

@implementation MCLBadgeView

#pragma mark - Initializers

- (instancetype)initWithCoder:(NSCoder*)coder
{
    if (self = [super initWithCoder:coder]) {
        [self configure];
    }

    return self;
}

- (instancetype)initWithFrame:(CGRect)rect
{
    if (self = [super initWithFrame:rect]) {
        [self configure];
    }

    return self;
}

- (void)configure
{
    self.layer.cornerRadius = 3;
    self.layer.masksToBounds = YES;
}

@end

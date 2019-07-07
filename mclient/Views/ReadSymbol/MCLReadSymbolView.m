//
//  MCLReadSymbolView.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLReadSymbolView.h"


@interface MCLReadSymbolView ()

@property (assign) BOOL drawn;

@end

@implementation MCLReadSymbolView

- (instancetype)initWithCoder:(NSCoder*)coder
{
    if (self = [super initWithCoder:coder]) {
        [self commonInit];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)rect
{
    if (self = [super initWithFrame:rect]) {
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit
{
    self.backgroundColor = [UIColor clearColor];
}

- (void)drawRect:(CGRect)rect
{
    self.drawn = YES;
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextAddEllipseInRect(ctx, rect);
    CGContextSetFillColor(ctx, CGColorGetComponents([self.color CGColor]));
    CGContextFillPath(ctx);
}

@end

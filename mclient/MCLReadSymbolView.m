//
//  MCLReadSymbolView.m
//  mclient
//
//  Created by Christopher Reitz on 29.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLReadSymbolView.h"

@interface MCLReadSymbolView ()

@property (assign) BOOL drawn;

@end

@implementation MCLReadSymbolView

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
    self.backgroundColor = [UIColor clearColor];
    self.color = [UIColor colorWithRed:0 green:0.478 blue:1 alpha:1.0];
}

- (void)drawRect:(CGRect)rect
{
//    if (self.drawn == NO) {
        self.drawn = YES;
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextAddEllipseInRect(ctx, rect);
        CGContextSetFillColor(ctx, CGColorGetComponents([self.color CGColor]));
        CGContextFillPath(ctx);
//    }
}

@end

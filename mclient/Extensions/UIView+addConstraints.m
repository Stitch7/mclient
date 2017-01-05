//
//  UIView+addConstraints.m
//  mclient
//
//  Created by Christopher Reitz on 30/12/2016.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

#import "UIView+addConstraints.h"

@implementation UIView (addConstraints)

- (void)addConstraints:(NSString *)string views:(NSDictionary<NSString *, id> *)views
{
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:string options:0 metrics:nil views:views];

    [self addConstraints:constraints];
}

@end


//
//  UIView+addConstraints.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "UIView+addConstraints.h"

@implementation UIView (addConstraints)

- (void)addConstraints:(NSString *)string views:(NSDictionary<NSString *, id> *)views
{
//    self.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:string options:0 metrics:nil views:views];
    [self addConstraints:constraints];
}

- (void)constrainEdgesTo:(UIView *)view
{
//    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self constrainEqual:NSLayoutAttributeTop toItem:view toAttribute:NSLayoutAttributeTop];
    [self constrainEqual:NSLayoutAttributeLeading toItem:view toAttribute:NSLayoutAttributeLeading];
    [self constrainEqual:NSLayoutAttributeTrailing toItem:view toAttribute:NSLayoutAttributeTrailing];
    [self constrainEqual:NSLayoutAttributeBottom toItem:view toAttribute:NSLayoutAttributeBottom];
}

- (void)constrainEdgesToMarginOf:(UIView *)view
{
//    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self constrainEqual:NSLayoutAttributeTop toItem:view toAttribute:NSLayoutAttributeTopMargin];
    [self constrainEqual:NSLayoutAttributeLeading toItem:view toAttribute:NSLayoutAttributeLeadingMargin];
    [self constrainEqual:NSLayoutAttributeTrailing toItem:view toAttribute:NSLayoutAttributeTrailingMargin];
    [self constrainEqual:NSLayoutAttributeBottom toItem:view toAttribute:NSLayoutAttributeBottomMargin];
}

- (void)constrainEqual:(NSLayoutAttribute)attribute toItem:(id)toItem toAttribute:(NSLayoutAttribute)toAttribute
{
//    self.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:(@[[NSLayoutConstraint constraintWithItem:self
                                                                            attribute:attribute
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:toItem
                                                                            attribute:toAttribute
                                                                           multiplier:1.0f
                                                                             constant:0.0f]])];
}

@end


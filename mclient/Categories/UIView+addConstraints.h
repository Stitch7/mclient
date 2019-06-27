//
//  UIView+addConstraints.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@interface UIView (addConstraints)

- (void)addConstraints:(NSString *)string views:(NSDictionary<NSString *, id> *)views;
- (void)constrainEdgesTo:(UIView *)view;
- (void)constrainEdgesToMarginOf:(UIView *)view;
- (void)constrainEqual:(NSLayoutAttribute)attribute toItem:(id)toItem toAttribute:(NSLayoutAttribute)toAttribute;

@end

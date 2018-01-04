//
//  MCLToast.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLTheme;

@interface MCLToast : UIVisualEffectView

- (instancetype)initWithTheme:(id <MCLTheme>)theme image:(UIImage *)image title:(NSString *)title;

@end

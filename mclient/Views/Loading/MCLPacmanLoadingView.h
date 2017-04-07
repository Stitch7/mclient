//
//  MCLPacmanLoadingView.h
//  mclient
//
//  Copyright © 2014 - 2017 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLTheme;

@interface MCLPacmanLoadingView : UIView

@property(strong, nonatomic) UIView *container;
@property(strong, nonatomic) UILabel *label;
@property(strong, nonatomic) UIActivityIndicatorView *spinner;

- (instancetype)initWithTheme:(id <MCLTheme>)theme;

- (void)configureSubviews;

@end

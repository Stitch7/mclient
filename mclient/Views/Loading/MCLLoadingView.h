//
//  MCLLoadingView.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@interface MCLLoadingView : UIView

@property(strong, nonatomic) UIView *container;
@property(strong, nonatomic) UILabel *label;
@property(strong, nonatomic) UIActivityIndicatorView *spinner;

- (void)configureSubviews;

@end

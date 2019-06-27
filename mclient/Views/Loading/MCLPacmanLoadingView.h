//
//  MCLPacmanLoadingView.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLTheme;

@interface MCLPacmanLoadingView : UIView

@property(strong, nonatomic) UIView *spinner;

- (instancetype)initWithTheme:(id <MCLTheme>)theme;

@end

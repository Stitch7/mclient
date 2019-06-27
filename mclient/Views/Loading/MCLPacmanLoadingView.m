//
//  MCLPacmanLoadingView.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLPacmanLoadingView.h"

#import "DGActivityIndicatorView.h"
#import "UIView+addConstraints.h"
#import "MCLThemeManager.h"
#import "MCLTheme.h"

@interface MCLPacmanLoadingView ()

@property (strong, nonatomic) id <MCLTheme> currentTheme;

@end

@implementation MCLPacmanLoadingView

#pragma mark - Initializers

- (instancetype)initWithTheme:(id <MCLTheme>)theme
{
    self = [super init];
    if (!self) return nil;

    self.currentTheme = theme;
    [self configureSubviews];

    return self;
}

- (void)configureSubviews
{
    DGActivityIndicatorView *pacmanView = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeCookieTerminator
                                                                              tintColor:[self.currentTheme loadingIndicatorColor]
                                                                                   size:32.0f];
    self.backgroundColor = [self.currentTheme backgroundColor];
    pacmanView.translatesAutoresizingMaskIntoConstraints = NO;

    pacmanView.backgroundColor = self.backgroundColor;
    [self addSubview:pacmanView];
    [pacmanView startAnimating];

    [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:pacmanView
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.0
                                                      constant:0]];

    [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:pacmanView
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1.0
                                                      constant:0]];

    self.spinner = pacmanView;
}

@end

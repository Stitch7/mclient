//
//  MCLErrorView.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLErrorView.h"

#import <QuartzCore/QuartzCore.h>

#import "UIView+addConstraints.h"


@implementation MCLErrorView

#pragma mark - Initializers

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self configureBasic];
    }

    return self;
}

- (instancetype)initWithFrame:(CGRect)frame hideSubLabel:(BOOL)hideSubLabel
{
    if (self = [super initWithFrame:frame]) {
        [self configureBasic];
        self.hideSubLabel = hideSubLabel;
    }

    return self;
}

- (instancetype)initWithFrame:(CGRect)frame andText:(NSString *)text
{
	if (self = [super initWithFrame:frame]) {
        self.labelText = text;
        [self configureBasic];
	}

	return self;
}

- (instancetype)initWithFrame:(CGRect)frame andText:(NSString *)text hideSubLabel:(BOOL)hideSubLabel
{
    if (self = [super initWithFrame:frame]) {
        self.labelText = text;
        [self configureBasic];
        self.hideSubLabel = hideSubLabel;
    }

    return self;
}

- (void)configureBasic
{
    UIView *mainView = self;

    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    UIEdgeInsets insets = UIEdgeInsetsMake(0, 0, 0, 0);
    scrollView.contentInset = insets;
    scrollView.scrollIndicatorInsets = insets;
    [self addSubview:scrollView];

    UIView *contentView = [[UIView alloc] init];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addSubview:contentView];

    NSDictionary* viewsDictionary = NSDictionaryOfVariableBindings(mainView, scrollView, contentView);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[scrollView]|" options:0 metrics:0 views:viewsDictionary]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[scrollView]|" options:0 metrics:0 views:viewsDictionary]];
    [scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[contentView]|" options:0 metrics:0 views:viewsDictionary]];
    [scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[contentView]|" options:0 metrics:0 views:viewsDictionary]];

    // Tie contentView width to main view width
    [mainView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[contentView(==mainView)]" options:0 metrics:0 views:viewsDictionary]];

    UIView *spacerTop = [[UIView alloc] init];
    spacerTop.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = [UIFont boldSystemFontOfSize:24.0f];
    label.textColor = [UIColor darkGrayColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;

    UIImageView *image = [[UIImageView alloc] init];
    image.translatesAutoresizingMaskIntoConstraints = NO;

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.titleLabel.font = [UIFont boldSystemFontOfSize:18.0f];
    [button setTitle: NSLocalizedString(@"Try again", nil) forState:UIControlStateNormal];
    button.contentEdgeInsets = UIEdgeInsetsMake(10, 15, 10, 15);
    button.layer.borderWidth = 2.0f;
    button.layer.cornerRadius = 10;
    button.layer.borderColor = button.tintColor.CGColor;

    UIButton *gameButton = [UIButton buttonWithType:UIButtonTypeSystem];
    gameButton.translatesAutoresizingMaskIntoConstraints = NO;
    gameButton.titleLabel.font = [UIFont systemFontOfSize:12.0f];
    [gameButton setTitle: NSLocalizedString(@"Let's play a game", nil) forState:UIControlStateNormal];

    UIView *spacerBottom = [[UIView alloc] init];
    spacerBottom.translatesAutoresizingMaskIntoConstraints = NO;

    [contentView addSubview:spacerTop];
    [contentView addSubview:label];
    [contentView addSubview:image];
    [contentView addSubview:button];
    [contentView addSubview:gameButton];
    [contentView addSubview:spacerBottom];

    [contentView addConstraints:@"H:|-[spacerTop]-|" views:NSDictionaryOfVariableBindings(spacerTop)];

    [contentView addConstraints:@"H:|-25-[label]-25-|" views:NSDictionaryOfVariableBindings(label)];

    // Center image horizontally
    [contentView addConstraint:[NSLayoutConstraint constraintWithItem:contentView
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:image
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.0
                                                      constant:0]];
    // Center image vertically
    [contentView addConstraint:[NSLayoutConstraint constraintWithItem:contentView
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:image
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1.0
                                                      constant:0]];

    // Center button horizontally
    [contentView addConstraint:[NSLayoutConstraint constraintWithItem:contentView
                                                            attribute:NSLayoutAttributeCenterX
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:button
                                                            attribute:NSLayoutAttributeCenterX
                                                           multiplier:1.0
                                                             constant:0]];

    [contentView addConstraint:[NSLayoutConstraint constraintWithItem:contentView
                                                            attribute:NSLayoutAttributeCenterX
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:gameButton
                                                            attribute:NSLayoutAttributeCenterX
                                                           multiplier:1.0
                                                             constant:0]];

    NSDictionary *views = NSDictionaryOfVariableBindings(spacerTop, label, image, button, gameButton, spacerBottom);
    [contentView addConstraints:@"V:|-[spacerTop(20)][label]-25-[image]-30-[button(36)]-40-[gameButton][spacerBottom]-|" views:views];

    [contentView addConstraints:@"H:|-[spacerBottom]-|" views:NSDictionaryOfVariableBindings(spacerBottom)];

    self.scrollView = scrollView;
    self.contentView = contentView;
    self.label = label;
    self.image = image;
    self.button = button;
    self.gameButton = gameButton;

    [self configure];
}

# pragma mark - Abstract

- (void)configure
{
    mustOverride();
}

@end

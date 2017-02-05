//
//  MCLErrorView.m
//  mclient
//
//  Created by Christopher Reitz on 13.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLErrorView.h"

#import "UIView+addConstraints.h"
#import "utils.h"

@implementation MCLErrorView

#pragma mark - Initializers

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self configureBasic];
    }

    return self;
}

- (id)initWithFrame:(CGRect)frame hideSubLabel:(BOOL)hideSubLabel
{
    if (self = [super initWithFrame:frame]) {
        [self configureBasic];
        self.hideSubLabel = hideSubLabel;
    }

    return self;
}

- (id)initWithFrame:(CGRect)frame andText:(NSString *)text
{
	if (self = [super initWithFrame:frame]) {
        self.labelText = text;
        [self configureBasic];
	}

	return self;
}

- (id)initWithFrame:(CGRect)frame andText:(NSString *)text hideSubLabel:(BOOL)hideSubLabel
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
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = [UIFont systemFontOfSize:15.0f];
    label.textColor = [UIColor darkGrayColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;

    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *subLabel = [[UILabel alloc] init];
    subLabel.translatesAutoresizingMaskIntoConstraints = NO;
    subLabel.font = [UIFont systemFontOfSize:13.0f];
    subLabel.textColor = [UIColor lightGrayColor];

    subLabel.text = NSLocalizedString(@"Try pull to refresh…", nil);

    [self addSubview:label];
    [self addSubview:imageView];
    [self addSubview:subLabel];

    // Center label horizontally
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:label
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.0
                                                      constant:0]];

    // Center image horizontally
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:imageView
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.0
                                                      constant:0]];

    // Center subLabel vertically
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:imageView
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1.0
                                                      constant:0]];

    // Center subLabel horizontally
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:subLabel
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.0
                                                      constant:0]];

    NSDictionary *views = NSDictionaryOfVariableBindings(label, imageView, subLabel);
    [self addConstraints:@"V:[label]-25-[imageView]-20-[subLabel]" views:views];

    self.label = label;
    self.image = imageView;
    self.subLabel = subLabel;

    [self configure];

    subLabel.hidden = self.hideSubLabel;
}

# pragma mark - Abstract

- (void)configure
{
    mustOverride();
}

@end

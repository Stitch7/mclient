//
//  MCLLoadingView.m
//  mclient
//
//  Created by Christopher Reitz on 12.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLLoadingView.h"
#import "UIView+addConstraints.h"

@implementation MCLLoadingView

#pragma mark - Initializers

- (id)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame]) {
        [self configureSubviews];
	}

	return self;
}

- (void)configureSubviews
{
    UIView *container = [[UIView alloc] init];
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    UILabel *label = [[UILabel alloc] init];

    container.translatesAutoresizingMaskIntoConstraints = NO;

    spinner.translatesAutoresizingMaskIntoConstraints = NO;
    [spinner startAnimating];

    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = NSLocalizedString(@"Loading…", nil);
    label.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    label.textColor = [UIColor darkGrayColor];

    [self addSubview:container];
    [container addSubview:label];
    [container addSubview:spinner];

    [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:container
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.0
                                                      constant:0]];

    [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:container
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1.0
                                                      constant:0]];

    NSDictionary *views = NSDictionaryOfVariableBindings(spinner, label);
    [container addConstraints:@"V:|[spinner]|" views:views];
    [container addConstraints:@"V:|[label]|" views:views];
    [container addConstraints:@"H:|[spinner]-5-[label]|" views:views];

    self.container = container;
    self.spinner = spinner;
    self.label = label;
}

@end

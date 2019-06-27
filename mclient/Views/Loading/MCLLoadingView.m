//
//  MCLLoadingView.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLLoadingView.h"
#import "UIView+addConstraints.h"

@implementation MCLLoadingView

#pragma mark - Initializers

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) return nil;

    [self configureSubviews];

	return self;
}

#pragma mark - Configuration

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

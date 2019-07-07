//
//  MCLLoadingTableViewCell.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLLoadingTableViewCell.h"

#import "UIView+addConstraints.h"
#import "MCLPacmanLoadingView.h"


NSString *const MCLLoadingTableViewCellIdentifier = @"LoadingCell";

@interface MCLLoadingTableViewCell ()

@property (strong, nonatomic) UIView *loadingView;

@end

@implementation MCLLoadingTableViewCell

- (instancetype)initWithLoadingView:(MCLPacmanLoadingView *)loadingView
{
    self = [super init];
    if (!self) return nil;

    self.loadingView = loadingView;

    return self;
}

- (void)setLoadingView:(MCLPacmanLoadingView *)loadingView
{
    self.backgroundView = [[UIView alloc] init];
    self.backgroundColor = [UIColor clearColor];
    self.layer.borderColor = [[UIColor clearColor] CGColor];
    loadingView.backgroundColor = [UIColor clearColor];
    loadingView.spinner.backgroundColor = [UIColor clearColor];

    [self addSubview:loadingView];
    loadingView.translatesAutoresizingMaskIntoConstraints = NO;
    [[loadingView.heightAnchor constraintEqualToConstant:100] setActive:YES];
    [loadingView constrainEdgesToMarginOf:self];
}

- (void)addSubview:(UIView *)view
{
    // Remove border / separator
    // The separator has a height of 0.5pt on a retina display and 1pt on non-retina.
    // Prevent subviews with this height from being added.
    if (CGRectGetHeight(view.frame) * [UIScreen mainScreen].scale == 1) {
        return;
    }

    [super addSubview:view];
}

@end

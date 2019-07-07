//
//  MCLNoDataTableViewCell.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLNoDataTableViewCell.h"

#import "UIView+addConstraints.h"
#import "MCLNoDataView.h"


NSString *const MCLNoDataTableViewCellIdentifier = @"NoDataCell";

@interface MCLNoDataTableViewCell ()

@property (strong, nonatomic) MCLNoDataView *noDataView;

@end

@implementation MCLNoDataTableViewCell

- (instancetype)initWithNoDataView:(MCLNoDataView *)noDataView
{
    self = [super init];
    if (!self) return nil;

    self.noDataView = noDataView;

    return self;
}

- (void)setNoDataView:(MCLNoDataView *)noDataView
{
    self.backgroundView = [[UIView alloc] init];
    self.backgroundColor = [UIColor clearColor];
    self.layer.borderColor = [[UIColor clearColor] CGColor];
    
    [self addSubview:noDataView];
    noDataView.translatesAutoresizingMaskIntoConstraints = NO;
    [noDataView constrainEdgesTo:self];
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

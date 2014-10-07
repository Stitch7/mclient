//
//  MCLLoadingView.m
//  mclient
//
//  Created by Christopher Reitz on 12.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLLoadingView.h"

@implementation MCLLoadingView

#pragma mark - Accessors
@synthesize label = _label;
@synthesize spinner = _spinner;

- (UILabel *)label
{
	if ( ! _label) {
		_label = [[UILabel alloc] initWithFrame:self.bounds];
	}

    return _label;
}

- (UIActivityIndicatorView *)spinner
{
	if ( ! _spinner) {
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }

	return _spinner;
}

#pragma mark - Initializers
- (id)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame]) {
        [self.spinner startAnimating];

        [self configureSubviews];

        [self addSubview:self.label];
        [self addSubview:self.spinner];

        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self setNeedsLayout];
	}

	return self;
}

- (void)configureSubviews
{
    [self setBackgroundColor:[UIColor whiteColor]];

    self.label.text = @"Loading…";
    self.label.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    self.label.textColor = self.spinner.color;

    self.spaceBetwennSpinnerAndLabel = 5;
}

#pragma mark - Layout Management
- (void)layoutSubviews
{
	// Calculate label size
    CGSize labelSize = [self.label.text boundingRectWithSize:CGSizeMake(280.0f, MAXFLOAT)
                                                     options:NSStringDrawingUsesLineFragmentOrigin
                                                  attributes:@{NSFontAttributeName:self.label.font}
                                                     context:nil].size;

	CGRect labelFrame;
	labelFrame.size = labelSize;
	self.label.frame = labelFrame;

	// Allign label and spinner horizontaly
	labelFrame = self.label.frame;
	CGRect spinnerFrame = self.spinner.frame;

    int spinnerWidth = [self.spinner isAnimating] ? spinnerFrame.size.width : 0;
    int spaceBetwennSpinnerAndLabel = [self.spinner isAnimating] ? self.spaceBetwennSpinnerAndLabel : 0;

    CGFloat totalWidth = spinnerWidth + spaceBetwennSpinnerAndLabel + labelSize.width;
	spinnerFrame.origin.x = self.bounds.origin.x + (self.bounds.size.width - totalWidth) / 2;
	labelFrame.origin.x = spinnerFrame.origin.x + spinnerWidth + spaceBetwennSpinnerAndLabel;

	// Set y position
    spinnerFrame.origin.y = (self.bounds.size.height - labelFrame.size.height) / 2;
	labelFrame.origin.y = spinnerFrame.origin.y;

    // Pass back modiefied frames
	self.label.frame = labelFrame;
	self.spinner.frame = spinnerFrame;
}

@end

//
//  MCLLoadingView.m
//  mclient
//
//  Created by Christopher Reitz on 12.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLLoadingView.h"

#pragma mark - Private Stuff
@interface MCLLoadingView()

@property(strong, nonatomic) UILabel *label;
@property(strong, nonatomic) UIActivityIndicatorView *spinner;

@end

@implementation MCLLoadingView

#pragma mark - Accessors
@synthesize label = _label;
@synthesize spinner = _spinner;

- (UILabel *)label
{
	if (!_label) {
		_label = [[UILabel alloc] initWithFrame:self.bounds];
		_label.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
	}
	return _label;
}

- (UIActivityIndicatorView *)spinner
{
	if (!_spinner) _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	return _spinner;
}

#pragma mark - Initializers
- (id)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame]) {
		[self setBackgroundColor:[UIColor whiteColor]];
		self.label.text = @"Loading…";
		self.label.textColor = self.spinner.color;
		[self.spinner startAnimating];
		
		[self addSubview:self.label];
		[self addSubview:self.spinner];
		
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self setNeedsLayout];
	}

	return self;
}

#pragma mark - Layout Management
#define SPACE_BETWEEN_SPINNER_AND_LABEL 5
- (void)layoutSubviews
{
	// Calculate label size
    CGSize labelSize = [self.label.text boundingRectWithSize:CGSizeMake(280.0f, MAXFLOAT)
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:[UIFont systemFontSize]]}
                                              context:nil].size;

	CGRect labelFrame;
	labelFrame.size = labelSize;
	self.label.frame = labelFrame;


	// Allign label and spinner horizontaly
	labelFrame = self.label.frame;
	CGRect spinnerFrame = self.spinner.frame;
	CGFloat totalWidth = spinnerFrame.size.width + SPACE_BETWEEN_SPINNER_AND_LABEL + labelSize.width;
	spinnerFrame.origin.x = self.bounds.origin.x + (self.bounds.size.width - totalWidth) / 2;
	labelFrame.origin.x = spinnerFrame.origin.x + spinnerFrame.size.width + SPACE_BETWEEN_SPINNER_AND_LABEL;

	// Set y position
    spinnerFrame.origin.y = 150;
	labelFrame.origin.y = 150;

	self.label.frame = labelFrame;
	self.spinner.frame = spinnerFrame;
}

@end

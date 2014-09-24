//
//  MCLLabelView.m
//  mclient
//
//  Created by Christopher Reitz on 19.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLDetailView.h"

#define LABEL_SIZE 15
#define SUB_LABEL_SIZE 13

#pragma mark - Private Stuff

@interface MCLDetailView()

@property(strong, nonatomic) UIImageView *image;
@property(strong, nonatomic) UILabel *label;
@property(strong, nonatomic) UILabel *subLabel;


@end

@implementation MCLDetailView

#pragma mark - Accessors

@synthesize image = _image;
@synthesize label = _label;
@synthesize subLabel = _subLabel;

- (UIImageView *)image
{
	if ( ! _image) {
        _image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logoDetailView.png"]];
    }

	return _image;
}

- (UILabel *)label
{
	if ( ! _label) {
		_label = [[UILabel alloc] initWithFrame:self.bounds];
		_label.font = [UIFont systemFontOfSize:LABEL_SIZE];
	}
	return _label;
}

- (UILabel *)subLabel
{
	if ( ! _subLabel) {
		_subLabel = [[UILabel alloc] initWithFrame:self.bounds];
		_subLabel.font = [UIFont systemFontOfSize:SUB_LABEL_SIZE];
	}
	return _subLabel;
}


#pragma mark - Initializers

- (id)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame]) {
        [self configureWithSubLabelText:@"Select a thread…"];
	}

	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if (self = [super initWithCoder:aDecoder]) {
        [self configureWithSubLabelText:@"Select a board…"];
	}
    
	return self;
}

- (void)configureWithSubLabelText:(NSString *)subLabelText
{
//    [self setBackgroundColor:[UIColor colorWithRed:248/255.0 green:248/255.0 blue:248/255.0 alpha:1.0]];
    [self setBackgroundColor:[UIColor whiteColor]];

//    self.label.text = @"Welcome Stitch";
//    self.label.textColor = [UIColor darkGrayColor];

    self.subLabel.text = subLabelText;


    [self addSubview:self.image];
//    [self addSubview:self.label];
    [self addSubview:self.subLabel];

    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self setNeedsLayout];
}

#pragma mark - Layout Management

- (void)layoutSubviews
{
	// Calculate label size
    CGSize labelSize = [self.label.text boundingRectWithSize:CGSizeMake(280.0f, MAXFLOAT)
                                                     options:NSStringDrawingUsesLineFragmentOrigin
                                                  attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:LABEL_SIZE]}
                                                     context:nil].size;

	CGRect labelFrame;
	labelFrame.size = labelSize;
	self.label.frame = labelFrame;

    // Calculate subLabel size
    CGSize subLabelSize = [self.subLabel.text boundingRectWithSize:CGSizeMake(280.0f, MAXFLOAT)
                                                           options:NSStringDrawingUsesLineFragmentOrigin
                                                        attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:SUB_LABEL_SIZE]}
                                                           context:nil].size;

	CGRect subLabelFrame;
	subLabelFrame.size = subLabelSize;
	self.subLabel.frame = subLabelFrame;


	// Allign label and spinner horizontaly
	labelFrame = self.label.frame;
	CGRect imageFrame = self.image.frame;

	imageFrame.origin.x = self.bounds.origin.x + (self.bounds.size.width - imageFrame.size.width) / 2;
	labelFrame.origin.x = self.bounds.origin.x + (self.bounds.size.width - labelFrame.size.width) / 2;
    subLabelFrame.origin.x = self.bounds.origin.x + (self.bounds.size.width - subLabelFrame.size.width) / 2;

	// Set y position
    imageFrame.origin.y = (self.bounds.size.height - imageFrame.size.height) / 2;
	labelFrame.origin.y = imageFrame.origin.y - 25;
    subLabelFrame.origin.y = imageFrame.origin.y + imageFrame.size.height + 20;

    // Pass back modiefied frames
	self.image.frame = imageFrame;
    self.label.frame = labelFrame;
    self.subLabel.frame = subLabelFrame;
}

@end

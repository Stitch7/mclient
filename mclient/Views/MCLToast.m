//
//  MCLToast.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLToast.h"

#import "UIView+addConstraints.h"
#import "MCLTheme.h"

@interface MCLToast ()

@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) NSString *title;

@end

@implementation MCLToast

- (instancetype)initWithTheme:(id <MCLTheme>)theme image:(UIImage *)image title:(NSString *)title
{
    self = [super initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    if (!self) return nil;

    self.image = image;
    self.title = title;
    [self configure];

    return self;
}

- (void)configure
{
    self.frame = CGRectMake(120, 250, 150, 150);
    self.layer.cornerRadius = 15;
    self.layer.masksToBounds = YES;

    UIImageView *image = [[UIImageView alloc] initWithImage:self.image];
    image.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:image];

    UILabel *title = [[UILabel alloc] init];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.textColor = [UIColor whiteColor];
    title.text = self.title;
    [self addSubview:title];

    [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:image
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.0
                                                      constant:0]];

    [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:title
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.0
                                                      constant:0]];

    NSDictionary *views = NSDictionaryOfVariableBindings(image, title);
    [self addConstraints:@"V:|[image]-5-[title]" views:views];
}

@end

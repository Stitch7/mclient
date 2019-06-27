//
//  MCLTextField.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLTextField.h"


@interface MCLTextField ()

@property (strong, nonatomic) UIImage *coloredClearImage;

@end

@implementation MCLTextField

#pragma mark - Initializers

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (!self) return nil;

    [self configure];

    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) return nil;

    [self configure];

    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [self tintClearImage];
}

#pragma mark - Configuration

- (void)configure
{
    self.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.clearButtonColor = self.tintColor;
}

#pragma mark - Private

- (void)tintClearImage
{
    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)subview;
            UIImage *image = [button imageForState:UIControlStateHighlighted];
            if (!self.coloredClearImage) {
                self.coloredClearImage = [self tintImage:image color:self.clearButtonColor];
            }
            [button setImage:self.coloredClearImage forState:UIControlStateNormal];
            [button setImage:self.coloredClearImage forState:UIControlStateHighlighted];
        }
    }
}

- (UIImage *)tintImage:(UIImage *)image color:(UIColor *)color
{
    CGSize size = image.size;
    UIGraphicsBeginImageContextWithOptions(size, NO, image.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [image drawAtPoint:CGPointZero blendMode:kCGBlendModeNormal alpha:1.0];

    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextSetBlendMode(context, kCGBlendModeSourceIn);
    CGContextSetAlpha(context, 1.0);

    CGRect rect = CGRectMake(CGPointZero.x, CGPointZero.y, image.size.width, image.size.height);
    CGContextFillRect(UIGraphicsGetCurrentContext(), rect);
    UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return tintedImage;
}

@end

//
//  MCLMultilineTitleLabel.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLMultilineTitleLabel.h"

#import "MCLTheme.h"
#import "MCLThemeManager.h"

@interface MCLMultilineTitleLabel ()

@property (strong, nonatomic) MCLThemeManager *themeManager;

@end

@implementation MCLMultilineTitleLabel

#pragma mark - Initializers

- (instancetype)initWithThemeManager:(MCLThemeManager *)themeManager andTitle:(NSString *)title
{
    self.themeManager = themeManager;

    self = [super init];
    if (!self) return nil;

    [self configureNotifications];
    [self configureWithTitle:title];

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Configuration

- (void)configureNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(themeChanged:)
                                                 name:MCLThemeChangedNotification
                                               object:nil];
}

- (void)configureWithTitle:(NSString *)title
{
    self.frame = CGRectMake(0, 0, 480, 44);
    self.font = [UIFont boldSystemFontOfSize: 15.0f];
    self.numberOfLines = 2;

    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:title];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 0.5;
    paragraphStyle.hyphenationFactor = 1.0;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, title.length)];
    self.attributedText = attributedString;

    [self sizeToFit];
    [self themeChanged:nil];
}

#pragma mark - Notifications

- (void)themeChanged:(NSNotification *)notification
{
    self.textColor = [self.themeManager.currentTheme textColor];
}

@end

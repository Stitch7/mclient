//
//  MCLTitleLabel.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLLogoLabel.h"
#import "MCLTheme.h"
#import "MCLThemeManager.h"

@interface MCLLogoLabel ()

@property (strong, nonatomic) MCLThemeManager *themeManager;

@end

@implementation MCLLogoLabel

#pragma mark - Initializers

- (instancetype)initWithThemeManager:(MCLThemeManager *)themeManager
{
    self = [super initWithFrame:CGRectMake(0, 0, 480, 44)];
    if (!self) return nil;

    self.themeManager = themeManager;
    [self configureNotifications];
    [self configureLayout];

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

- (void)configureLayout
{
    self.backgroundColor = [UIColor clearColor];
    self.numberOfLines = 2;
    self.font = [UIFont systemFontOfSize:26.0f weight:UIFontWeightThin];
    self.textAlignment = NSTextAlignmentCenter;
    [self updateTextColorFromTheme];
    self.text = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
}

- (void)updateTextColorFromTheme
{
    self.textColor = self.themeManager.currentTheme.textColor;
}

#pragma mark - Notifications

- (void)themeChanged:(NSNotification *)notification
{
    [self updateTextColorFromTheme];
}

@end

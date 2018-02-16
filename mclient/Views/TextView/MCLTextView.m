//
//  MCLTextView.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLTextView.h"

#import "MCLTheme.h"
#import "MCLThemeManager.h"

@implementation MCLTextView

@synthesize themeManager = _themeManager;

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self configure];
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self configure];
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)configure
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(themeChanged:)
                                                 name:MCLThemeChangedNotification
                                               object:nil];
}

- (void)setThemeManager:(MCLThemeManager *)themeManager
{
    _themeManager = themeManager;
    [self themeChanged:nil];
}

#pragma mark - Notifications

- (void)themeChanged:(NSNotification *)notification
{
    id <MCLTheme> currentTheme = self.themeManager.currentTheme;
    self.keyboardAppearance = [currentTheme isDark] ? UIKeyboardAppearanceDark : UIKeyboardAppearanceLight;
    self.textColor = [currentTheme textViewTextColor];
}

@end

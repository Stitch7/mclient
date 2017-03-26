//
//  MCLTextView.m
//  mclient
//
//  Created by Christopher Reitz on 13/01/2017.
//  Copyright © 2017 Christopher Reitz. All rights reserved.
//

#import "MCLTextView.h"

#import "MCLTheme.h"
#import "MCLThemeManager.h"

@implementation MCLTextView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self configure];
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
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

    [self themeChanged:nil];
}

#pragma mark - Notifications

- (void)themeChanged:(NSNotification *)notification
{
    id <MCLTheme> currentTheme = [[MCLThemeManager sharedManager] currentTheme];
    self.keyboardAppearance = [currentTheme isDark] ? UIKeyboardAppearanceDark : UIKeyboardAppearanceLight;
    self.textColor = [currentTheme textViewTextColor];
}

@end

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

- (void)configure
{
    id <MCLTheme> theme = [[MCLThemeManager sharedManager] currentTheme];
    self.keyboardAppearance = [theme isDark] ? UIKeyboardAppearanceDark : UIKeyboardAppearanceLight;
    self.textColor = [theme textViewTextColor];
}

@end

//
//  MCLVerifiyLoginView.m
//  mclient
//
//  Created by Christopher Reitz on 25.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLVerifiyLoginView.h"

#import "UIView+addConstraints.h"
#import "MCLTheme.h"
#import "MCLThemeManager.h"

@implementation MCLVerifiyLoginView

- (void)configureSubviews
{
    [super configureSubviews];
    
    [self setBackgroundColor:[UIColor clearColor]];

    id <MCLTheme> currentTheme = [[MCLThemeManager sharedManager] currentTheme];
    self.label.textColor = [currentTheme textColor];
    self.label.font = [UIFont systemFontOfSize:13.0f];
    self.label.text = NSLocalizedString(@"Verifying login data…", nil);
}

- (void)loginStatusWithUsername:(NSString *)username
{
    [self hideSpinner];
    self.label.text = [NSString stringWithFormat:NSLocalizedString(@"Welcome %@", nil), username];
}

- (void)loginStatusNoLogin
{
    [self hideSpinner];
    self.label.text = NSLocalizedString(@"You are not logged in", nil);
}

-(void)hideSpinner
{
    [self.spinner stopAnimating];
    [self.spinner removeFromSuperview];

    UILabel *label = self.label;
    NSDictionary *views = NSDictionaryOfVariableBindings(label);
    [self.container addConstraints:@"H:|[label]|" views:views];
}

@end

//
//  MCLVerifiyLoginView.m
//  mclient
//
//  Copyright © 2014 - 2017 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLVerifiyLoginView.h"

#import "UIView+addConstraints.h"
#import "MCLTheme.h"
#import "MCLThemeManager.h"

@interface MCLVerifiyLoginView ()

@property (strong, nonatomic) MCLThemeManager *themeManager;

@end

@implementation MCLVerifiyLoginView

#pragma mark - Initializers

- (instancetype)initWithThemeManager:(MCLThemeManager *)themeManager
{
    self.themeManager = themeManager;
    self.frame = CGRectMake(0, 0, 200, 44);

    self = [super init];
    if (!self) return nil;

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)configureSubviews
{
    [super configureSubviews];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(themeChanged:)
                                                 name:MCLThemeChangedNotification
                                               object:nil];

    [self setBackgroundColor:[UIColor clearColor]];

    self.label.font = [UIFont systemFontOfSize:13.0f];
    self.label.text = NSLocalizedString(@"Verifying login data…", nil);

    [self themeChanged:nil];
}

#pragma mark - Public

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

- (void)hideSpinner
{
    [self.spinner stopAnimating];
    [self.spinner removeFromSuperview];

    UILabel *label = self.label;
    NSDictionary *views = NSDictionaryOfVariableBindings(label);
    [self.container addConstraints:@"H:|[label]|" views:views];
}

#pragma mark - Notifications

- (void)themeChanged:(NSNotification *)notification
{
    self.label.textColor = [self.themeManager.currentTheme textColor];
}

@end

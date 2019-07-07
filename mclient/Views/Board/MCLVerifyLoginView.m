//
//  MCLVerifyLoginView.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLVerifyLoginView.h"

#import "MCLTheme.h"
#import "MCLThemeManager.h"


@interface MCLVerifyLoginView ()

@property (strong, nonatomic) MCLThemeManager *themeManager;

@end

@implementation MCLVerifyLoginView

#pragma mark - Initializers

- (instancetype)initWithThemeManager:(MCLThemeManager *)themeManager
{
    self.themeManager = themeManager;
    self.frame = CGRectMake(0, 0, 200, 44);

    self = [super init];
    if (!self) return nil;

    [self configureSubviews];

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)configureSubviews
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(themeChanged:)
                                                 name:MCLThemeChangedNotification
                                               object:nil];

    self.titleLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    self.backgroundColor = [UIColor clearColor];
    self.enabled = NO;
    [self themeChanged:nil];
}

#pragma mark - Public

- (void)loginStatusWithUsername:(NSString *)username
{
    self.enabled = NO;
    [self setTitle:[NSString stringWithFormat:NSLocalizedString(@"Welcome %@", nil), username] forState:UIControlStateNormal];
    [self themeChanged:nil];
}

- (void)loginStatusNoLogin
{
    self.enabled = NO;
    [self setTitle:NSLocalizedString(@"You are not logged in", nil) forState:UIControlStateNormal];
    [self themeChanged:nil];
}

- (void)setNumberOfDrafts:(NSNumber *)numberOfDrafts
{
    if ([numberOfDrafts intValue] == 0) {
        return;
    }

    self.enabled = YES;
    NSString *title = [numberOfDrafts intValue] > 1
        ? NSLocalizedString(@"multiple_drafts", nil)
        : NSLocalizedString(@"one_draft", nil);
    [self setTitle:[NSString stringWithFormat:title, numberOfDrafts] forState:UIControlStateNormal];
    [self themeChanged:nil];
}

- (void)setNumberOfDrafts:(NSNumber *)numberOfDrafts withDelay:(double)delayInSeconds
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
        [self setNumberOfDrafts:numberOfDrafts];
    });
}

#pragma mark - Notifications

- (void)themeChanged:(NSNotification *)notification
{
    UIColor *titleColor = self.enabled
        ? [self.themeManager.currentTheme tintColor]
        : [self.themeManager.currentTheme textColor];
    [self setTitleColor:titleColor forState:UIControlStateNormal];
    [self sizeToFit];
}

@end

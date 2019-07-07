//
//  MCLLogoLabel.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLLogoLabel.h"
#import "MCLTheme.h"
#import "MCLDependencyBag.h"
#import "MCLFeatures.h"
#import "MCLThemeManager.h"
#import "MCLSoundEffectPlayer.h"
#import "MCLRouter.h"

@interface MCLLogoLabel ()

@property (strong, nonatomic) id <MCLDependencyBag> bag;

@end

@implementation MCLLogoLabel

#pragma mark - Initializers

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag
{
    self = [super initWithFrame:CGRectMake(0, 0, 480, 44)];
    if (!self) return nil;

    self.bag = bag;
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

    UITapGestureRecognizer *tripleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(trippleTapped:)];
    tripleTapRecognizer.numberOfTapsRequired = 3;
    self.userInteractionEnabled = YES;
    [self addGestureRecognizer:tripleTapRecognizer];
}

- (void)updateTextColorFromTheme
{
    self.textColor = self.bag.themeManager.currentTheme.textColor;
}

- (void)trippleTapped:(id)sender
{
    if (![self.bag.features isFeatureWithNameEnabled:MCLFeatureTetris]) {
        return;
    }

    [self.bag.soundEffectPlayer playSecretFoundSound];
//    [self.bag.router modalToGame];

    UIViewController *presentingVC = [UIApplication sharedApplication].windows.firstObject.rootViewController;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"You've found it" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [presentingVC dismissViewControllerAnimated:YES completion:nil];
    }]];
    [presentingVC presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Notifications

- (void)themeChanged:(NSNotification *)notification
{
    [self updateTextColorFromTheme];
}

@end

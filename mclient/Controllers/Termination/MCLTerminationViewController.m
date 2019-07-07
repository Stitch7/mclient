//
//  MCLTerminationViewController.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLTerminationViewController.h"

#import "UIApplication+Additions.h"
#import "MCLDependencyBag.h"
#import "MCLRouter+openURL.h"
#import "MCLThemeManager.h"
#import "MCLTheme.h"


@interface MCLTerminationViewController ()

@property (strong, nonatomic) id <MCLDependencyBag> bag;
@property (strong, nonatomic) UIApplication *application;

@property (weak, nonatomic) IBOutlet UILabel *headerLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UILabel *signatureLabel;
@property (weak, nonatomic) IBOutlet UIButton *appStoreButton;
@property (weak, nonatomic) IBOutlet UIButton *quitButton;

@end

@implementation MCLTerminationViewController

#pragma mark - Initializers

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag
{
    self = [super init];
    if (!self) return nil;

    self.bag = bag;

    return self;
}

#pragma mark - UIViewController life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [self.bag.themeManager.currentTheme backgroundColor];
    [self configureLabels];
    [self resetBadgeIcon];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return [self.bag.themeManager.currentTheme isDark]
        ? UIStatusBarStyleLightContent
        : UIStatusBarStyleDefault;
}

#pragma mark - Configuration

- (void)configureLabels
{
    self.headerLabel.text = NSLocalizedString(@"header", nil);
    self.messageLabel.text = NSLocalizedString(@"message", nil);
    self.signatureLabel.text = NSLocalizedString(@"signature", nil);
    [self.appStoreButton setTitle:NSLocalizedString(@"appStoreButton", nil) forState:UIControlStateNormal];
    [self.quitButton setTitle:NSLocalizedString(@"quitButton", nil) forState:UIControlStateNormal];
}

- (void)resetBadgeIcon
{
    [self.bag.application setApplicationIconBadgeNumber:0];
}

#pragma mark - Actions

- (IBAction)appStoreButtonPressed:(id)sender
{
    [self.bag.router openLinkInSafari:[NSURL URLWithString:kAppStoreUrl]];
}

- (IBAction)quitButtonPressed:(id)sender
{
    [self.bag.application quit];
}

@end

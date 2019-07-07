//
//  MCLSplitViewController.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLSplitViewController.h"

#import "MCLDependencyBag.h"
#import "MCLThemeManager.h"
#import "MCLTheme.h"

@interface MCLSplitViewController ()

@property (strong, nonatomic) id <MCLDependencyBag> bag;

@end

@implementation MCLSplitViewController

#pragma mark - Initializers

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag
{
    self = [super init];
    if (!self) return nil;

    self.bag = bag;

    return self;
}

#pragma mark - UISplitViewController overrides

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.maximumPrimaryColumnWidth = 350;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return [self.bag.themeManager.currentTheme isDark]
        ? UIStatusBarStyleLightContent
        : UIStatusBarStyleDefault;
}

@end

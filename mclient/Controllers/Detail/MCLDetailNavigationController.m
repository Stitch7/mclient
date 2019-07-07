//
//  MCLDetailNavigationController.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLDetailNavigationController.h"

#import "MCLDependencyBag.h"
#import "MCLRouter.h"
#import "MCLSplitViewController.h"


NSString * const MCLDisplayModeChangedNotification = @"MCLDisplayModeChangedNotification";

@interface MCLDetailNavigationController () <UINavigationControllerDelegate>

@property (strong, nonatomic) id <MCLDependencyBag> bag;
@property (strong, nonatomic) UIImage *displayModeButtonItemImage;

@end

@implementation MCLDetailNavigationController

#pragma mark - Initializers

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag rootViewController:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    if (!self) return nil;

    self.bag = bag;
    self.delegate = self;

    return self;
}

#pragma mark - Lazy Properties

- (UIImage *)displayModeButtonItemImage
{
    if (!_displayModeButtonItemImage) {
        _displayModeButtonItemImage = self.bag.router.splitViewController.displayModeButtonItem.image;
    }

    return _displayModeButtonItemImage;
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    UIViewController *detailVC = navigationController.viewControllers.firstObject;
    UIBarButtonItem *item = detailVC.navigationItem.leftBarButtonItem;
    if (!item) {
        item = [[UIBarButtonItem alloc] initWithImage:self.displayModeButtonItemImage
                                  landscapeImagePhone:self.displayModeButtonItemImage
                                                style:UIBarButtonItemStylePlain
                                               target:self
                                               action:@selector(displayModeButtonItemPressed:)];
    }

    viewController.navigationItem.leftBarButtonItem = item;
    viewController.navigationItem.leftItemsSupplementBackButton = YES;
}

#pragma mark - Actions

- (void)displayModeButtonItemPressed:(UIBarButtonItem *)sender
{
    UIImage *spitViewButtonImage;
    if (sender.tag == 0) {
        spitViewButtonImage = [UIImage imageNamed:@"spitViewButtonCollapsed"];
        sender.tag = 1;
    } else {
        spitViewButtonImage = self.displayModeButtonItemImage;
        sender.tag = 0;
    }

    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:spitViewButtonImage
                                               landscapeImagePhone:spitViewButtonImage
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(displayModeButtonItemPressed:)];

    item.tag = sender.tag;
    UIBarButtonItem *displayModeButtonItem = self.bag.router.splitViewController.displayModeButtonItem;

    // Use the afterDelay variant to avoid the possible leak warning
    [displayModeButtonItem.target performSelector:displayModeButtonItem.action
                                       withObject:nil
                                       afterDelay:0];

    [[NSNotificationCenter defaultCenter] postNotificationName:MCLDisplayModeChangedNotification
                                                        object:self
                                                      userInfo:nil];

    for (UIViewController *detailVC in self.viewControllers) {
        detailVC.navigationItem.leftBarButtonItem = item;
    }
}

@end

//
//  MCLModalNavigationController.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLModalNavigationController.h"

#import "MCLModalTransitioningDelegate.h"


@interface MCLModalNavigationController ()

@property(strong, nonatomic) id<UIViewControllerTransitioningDelegate> transitioningDelegate;

@end

@implementation MCLModalNavigationController

#pragma mark - Initializers

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    if (!self) return nil;

    [self configure];

    return self;
}

#pragma mark - Configuration

- (void)configure
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        self.modalPresentationStyle = UIModalPresentationPageSheet;
        if (self.viewControllers.firstObject.modalPresentationStyle != 0) {
            self.modalPresentationStyle = self.viewControllers.firstObject.modalPresentationStyle;
        }
    } else {
        self.transitioningDelegate = [[MCLModalTransitioningDelegate alloc] init];
        self.modalPresentationStyle = UIModalPresentationCustom;
        self.modalPresentationCapturesStatusBarAppearance = YES;
    }
}

#pragma mark - View Controller life cycle

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end

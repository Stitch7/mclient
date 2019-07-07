//
//  MCLModalPresentationController.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLModalPresentationController.h"


@interface MCLModalPresentationController ()

@property (strong, nonatomic) UIView *dimmingView;

@end

@implementation MCLModalPresentationController

- (instancetype)initWithPresentedViewController:(UIViewController *)presentedViewController presentingViewController:(nullable UIViewController *)presentingViewController
{
    self = [super initWithPresentedViewController:presentedViewController presentingViewController:presentingViewController];
    if (!self) return nil;

    [self configure];

    return self;
}

- (void)configure
{
    self.dimmingView = [[UIView alloc] init];
    self.dimmingView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
}

- (void)presentationTransitionWillBegin
{
    if (self.containerView == nil) {
        return;
    }

    self.dimmingView.frame = self.containerView.bounds;
    self.dimmingView.alpha = 0.0;
    [self.containerView insertSubview:self.dimmingView atIndex:0];

    [self.presentedViewController.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
        self.dimmingView.alpha = 1.0;
    } completion:nil];
}

- (void)dismissalTransitionWillBegin
{
    [self.presentedViewController.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
                                                                                        self.dimmingView.alpha = 0.0;

                                                                                        // WORKAROUND:
                                                                                        // It seems there is a bug in UIPresentationController in iOS11 + iOS12
                                                                                        // whereby the frame of presentingViewController gets corrupted after screen rotation
                                                                                        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
                                                                                        CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
                                                                                        self.presentingViewController.view.frame = CGRectMake(0.0, 0.0, screenWidth, screenHeight);
                                                                                    }
                                                                        completion:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
                                                                                        [self.dimmingView removeFromSuperview];
                                                                                    }];
}

- (CGRect)frameOfPresentedViewInContainerView
{
    if (self.containerView == nil) {
        return CGRectZero;
    }

    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    BOOL isPortrait = orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown;
    BOOL hasNotch = [UIApplication sharedApplication].statusBarFrame.size.height > 20.0;
    CGFloat portraitTopOffset = hasNotch ? 48.0 : 40.0;
    CGFloat topOffset = isPortrait ? portraitTopOffset : 0.0;
    CGFloat width = self.containerView.bounds.size.width;
    CGFloat height = self.containerView.bounds.size.height - topOffset;

    return CGRectMake(0, topOffset, width, height);
}

- (void)containerViewWillLayoutSubviews
{
    if (CGRectIsNull(self.containerView.bounds)) {
        return;
    }

    self.dimmingView.frame = self.containerView.bounds;
    self.presentedView.frame = self.frameOfPresentedViewInContainerView;
}

@end

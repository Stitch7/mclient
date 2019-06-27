//
//  MCLModalTransitionAnimator.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLModalTransitionAnimator.h"

#import "MCLModalOverlayView.h"


@implementation MCLModalTransitionAnimator

#pragma mark - Initializers

- (instancetype)init
{
    self = [super init];
    if (!self) return nil;

    self.presenting = NO;

    return self;
}

#pragma mark - UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0.8;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *fromView = fromVC.view;
    UIView *toView = toVC.view;

    CGPoint center = CGPointZero;
    if (self.isPresenting) {
        center = toView.center;
        toView.center = CGPointMake(center.x, toView.bounds.size.height);
        [transitionContext.containerView addSubview:toView];
        [self addOverlayToViewController:fromVC];
    } else {
        center = CGPointMake(toView.center.x, toView.bounds.size.height + fromView.bounds.size.height);
        [self removeOverlayFromViewController:toVC];
    }

    [UIView animateWithDuration:[self transitionDuration:transitionContext]
                          delay:0
         usingSpringWithDamping:300.0
          initialSpringVelocity:10.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         if (self.isPresenting) {
                             toView.center = center;
                             fromView.transform = CGAffineTransformMakeScale(0.92, 0.92);

                             [self addRoundedCornersToView:toView];
                             [self addRoundedCornersToView:fromView];
                         } else {
                             fromView.center = center;
                             toView.transform = CGAffineTransformIdentity;

                             [self removeRoundedCornersFromView:toView];
                             [self removeRoundedCornersFromView:fromView];
                         }
                     }
                     completion:^(BOOL finished) {
                         if (!self.isPresenting) {
                             [fromView removeFromSuperview];
                         }

                         [transitionContext completeTransition:YES];
                     }];
}

#pragma mark - Helper

- (void)addOverlayToViewController:(UIViewController *)viewController
{
    UINavigationController *navVC = ((UISplitViewController *)viewController).viewControllers.firstObject;
    MCLModalOverlayView *overlayView = [[MCLModalOverlayView alloc] initWithFrame:navVC.view.bounds];
    [navVC.view insertSubview:overlayView atIndex:0];
    [navVC.view bringSubviewToFront:overlayView];
}

- (void)removeOverlayFromViewController:(UIViewController *)viewController
{
    UINavigationController *navVC = ((UINavigationController *)viewController).viewControllers.firstObject;
    [navVC.view.subviews.lastObject removeFromSuperview];
}

- (void)addRoundedCornersToView:(UIView *)view
{
    view.layer.cornerRadius = 10;
    view.layer.masksToBounds = true;
}

- (void)removeRoundedCornersFromView:(UIView *)view
{
    view.layer.cornerRadius = 0;
    view.layer.masksToBounds = false;
}

@end

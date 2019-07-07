//
//  MCLModalTransitioningDelegate.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLModalTransitioningDelegate.h"

#import "MCLModalTransitionAnimator.h"
#import "MCLModalPresentationController.h"


@implementation MCLModalTransitioningDelegate

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented
                                                      presentingViewController:(UIViewController *)presenting
                                                          sourceViewController:(UIViewController *)source
{
    return [[MCLModalPresentationController alloc] initWithPresentedViewController:presented
                                                          presentingViewController:presenting];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source
{
    MCLModalTransitionAnimator *animator = [[MCLModalTransitionAnimator alloc] init];
    animator.presenting = YES;

    return animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    MCLModalTransitionAnimator *animator = [[MCLModalTransitionAnimator alloc] init];
    animator.presenting = NO;

    return animator;
}

@end

//
//  MCLModalTransitionAnimator.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLModalTransitionAnimator.h"

#import "MCLBoardListTableViewController.h"
#import "MCLSectionLoadingViewController.h"

@implementation MCLModalTransitionAnimator

- (instancetype)init
{
    self = [super init];
    if (!self) return nil;

    [self configure];

    return self;
}

- (void)configure
{
    self.presenting = NO;
}

- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0.8;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    UIView *fromView = [[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey] view];
    UIView *toView = [[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey] view];

    CGPoint center = CGPointZero;
    if (self.isPresenting) {
        center = toView.center;
        toView.center = CGPointMake(center.x, toView.bounds.size.height);
        [transitionContext.containerView addSubview:toView];
    } else {
        center = CGPointMake(toView.center.x, toView.bounds.size.height + fromView.bounds.size.height);
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

//                             UISplitViewController *splitVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
//                             UINavigationController *navVC = [splitVC.viewControllers firstObject];
//                             MCLSectionLoadingViewController *loadingVC = (MCLSectionLoadingViewController *)navVC.topViewController;
//                             MCLBoardListTableViewController *boardsVC = (MCLBoardListTableViewController *)loadingVC.contentViewController;
//
////                             UIView *deckView = [[UIView alloc] initWithFrame:fromView.frame];
////                             deckView.backgroundColor = [UIColor redColor];
////                             [boardsVC.view addSubview:deckView];
////                             [boardsVC.view bringSubviewToFront:deckView];
//
//                             boardsVC.tableView.backgroundColor = [UIColor darkGrayColor];

                         } else {
                             fromView.center = center;
                             toView.transform = CGAffineTransformMakeScale(1.0, 1.0);
                         }
                     }
                     completion:^(BOOL finished) {
                         if (!self.isPresenting) {
                             [fromView removeFromSuperview];
                         }

                         [transitionContext completeTransition:YES];
                     }];
}

@end

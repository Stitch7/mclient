//
//  MCLModalTransitionAnimator.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@interface MCLModalTransitionAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@property (assign, nonatomic, getter=isPresenting) BOOL presenting;

@end

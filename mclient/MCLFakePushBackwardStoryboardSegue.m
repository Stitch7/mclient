//
//  MCLFakePushBackwardStoryboardSegue.m
//  mclient
//
//  Created by Christopher Reitz on 23.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLFakePushBackwardStoryboardSegue.h"

@implementation MCLFakePushBackwardStoryboardSegue

- (void)perform
{
    UIView *preV = ((UIViewController *)self.sourceViewController).view;
    UIView *newV = ((UIViewController *)self.destinationViewController).view;

    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    newV.center = CGPointMake(preV.center.x - preV.frame.size.width, newV.center.y);
    [window insertSubview:newV aboveSubview:preV];

    [UIView animateWithDuration:0.4
                     animations:^{
                         newV.center = CGPointMake(preV.center.x, newV.center.y);
                         preV.center = CGPointMake(preV.center.x + preV.frame.size.width, newV.center.y);}
                     completion:^(BOOL finished){
                         [preV removeFromSuperview];
                         window.rootViewController = self.destinationViewController;
                     }];
}

@end

//
//  MCLAppDelegate.m
//  mclient
//
//  Created by Christopher Reitz on 21.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLAppDelegate.h"

#import "MCLMessageListViewController.h"
#import "MCLComposeMessagePreviewViewController.h"

@implementation MCLAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[NSUserDefaults standardUserDefaults] synchronize];
}


# pragma mark Global methods

- (CGRect)fullScreenFrameFromViewController:(UIViewController *)viewController
{
    CGFloat x = 0.0f;
    CGFloat y = 0.0f;

    CGFloat viewWidth = viewController.view.bounds.size.width;

    CGFloat navBarHeight = viewController.navigationController.navigationBar.bounds.size.height;
    CGSize statusBarSize = [UIApplication sharedApplication].statusBarFrame.size;
    CGFloat statusBarHeight = statusBarSize.height;
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if ((NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1) &&
        UIInterfaceOrientationIsLandscape(interfaceOrientation)
    ) {
        statusBarHeight = statusBarSize.width;
    }

    CGFloat viewHeight = viewController.view.bounds.size.height - navBarHeight - statusBarHeight;

    if ([[viewController class] isSubclassOfClass: [MCLMessageListViewController class]]) {
        y = navBarHeight + statusBarHeight;
    } else if ([[viewController class] isSubclassOfClass: [MCLComposeMessagePreviewViewController class]]) {
        y = navBarHeight;
        viewHeight += statusBarHeight;
    }

    return CGRectMake(x, y, viewWidth, viewHeight);
}

@end

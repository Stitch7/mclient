//
//  MCLAppDelegate.m
//  mclient
//
//  Created by Christopher Reitz on 21.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLAppDelegate.h"

@implementation MCLAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[NSUserDefaults standardUserDefaults] synchronize];
}


# pragma mark Global methods

- (CGRect)fullScreenFrameFromViewController:(UIViewController *)viewController
{
    BOOL isPortrait = UIInterfaceOrientationIsPortrait(viewController.interfaceOrientation);
    BOOL isLandscape = UIInterfaceOrientationIsLandscape(viewController.interfaceOrientation);

    // Fix width for when in splitView
    CGFloat viewWidth = viewController.splitViewController ? 320 : viewController.view.bounds.size.width;

    CGFloat viewHeight = viewController.view.bounds.size.height;
    // If iPad starts in landscape mode, subtract some points...
    viewHeight = isLandscape && viewController.splitViewController ? viewHeight - 250 : viewHeight;
    // Add missing navBar points in landscape mode for iPhone
    viewHeight = viewController.splitViewController ? viewHeight : viewHeight + 12;

    CGFloat navBarHeight = viewController.navigationController.navigationBar.bounds.size.height;

    CGSize statusBarSize = [UIApplication sharedApplication].statusBarFrame.size;
    CGFloat statusBarHeight = (isPortrait ? statusBarSize.height : statusBarSize.width);

    return CGRectMake(0, 0, viewWidth, viewHeight - navBarHeight - statusBarHeight);
}


@end

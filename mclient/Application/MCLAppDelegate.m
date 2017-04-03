//
//  MCLAppDelegate.m
//  mclient
//
//  Created by Christopher Reitz on 21.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLAppDelegate.h"
#import "UIApplication+Additions.h"
#import "MCLThemeManager.h"
#import "MCLNotificationManager.h"

@implementation MCLAppDelegate

@synthesize notificationAlert = _notificationAlert;

# pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[MCLThemeManager sharedManager] loadTheme];

    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [[MCLThemeManager sharedManager] loadTheme];
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [[MCLNotificationManager sharedNotificationManager] notificateAboutNewResponsesWithCompletionHandler:completionHandler];
}

@end

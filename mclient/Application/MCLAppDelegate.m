//
//  MCLAppDelegate.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLAppDelegate.h"

#import "UIApplication+Additions.h"
#import "MCLAppDependencyBag.h"
#import "MCLFeatures.h"
#import "MCLThemeManager.h"
#import "MCLNotificationManager.h"
#import "MCLRouter.h"
#import "MCLAppRouterDelegate.h"


@implementation MCLAppDelegate

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.bag = [[MCLAppDependencyBag alloc] init];
    self.window = [self.bag makeRootWindow];

    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [self.bag.themeManager loadTheme];
}

//- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
//{
//    [self.bag.notificationManager notificateAboutNewResponsesWithCompletionHandler:completionHandler];
//}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    NSLog(@"-------------------------");
    NSLog(@"DID RECEIVE NOTIFICATION:");
    NSLog(@"%@", notification);
    NSLog(@"-------------------------");
}

@end

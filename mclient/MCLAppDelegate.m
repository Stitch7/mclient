//
//  MCLAppDelegate.m
//  mclient
//
//  Created by Christopher Reitz on 21.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLAppDelegate.h"

#import "EDSunriseSet.h"
#import "MCLThemeManager.h"
#import "MCLDefaultTheme.h"
#import "MCLNightTheme.h"
#import "MCLMessageListViewController.h"
#import "MCLComposeMessagePreviewViewController.h"

@implementation MCLAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self initiliazeSunriseSet];
    [self initiliazeTheme];

    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)applicationWillEnterForeground:(UIApplication *)application
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"nightModeAutomatically"]) {
        return;
    }

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    MCLThemeManager *themeManager = [MCLThemeManager sharedManager];

    if ([userDefaults integerForKey:@"theme"] == kMCLThemeNight) {
        [themeManager applyTheme:[[MCLDefaultTheme alloc] init]];
        [userDefaults setInteger:kMCLThemeDefault forKey:@"theme"];
    }
    else {
        [themeManager applyTheme:[[MCLNightTheme alloc] init]];
        [userDefaults setInteger:kMCLThemeNight forKey:@"theme"];
    }
    [userDefaults synchronize];
}

-(void)initiliazeTheme
{
    MCLThemeManager *themeManager = [MCLThemeManager sharedManager];
    NSUInteger themeName = [[NSUserDefaults standardUserDefaults] integerForKey:@"theme"];

    if (themeName == kMCLThemeNight) {
        [themeManager applyTheme:[[MCLNightTheme alloc] init]];
    } else {
        [themeManager applyTheme:[[MCLDefaultTheme alloc] init]];
    }
}

-(void)initiliazeSunriseSet
{

}

@end

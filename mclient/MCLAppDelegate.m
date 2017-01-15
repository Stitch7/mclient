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
    [self initiliazeLocationManager];
    [self initiliazeSunrise];
    [self initiliazeTheme];

    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)applicationWillEnterForeground:(UIApplication *)application
{
    [self switchThemeBasedOnTime];
}

-(void)initiliazeLocationManager
{
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
}

-(void)initiliazeSunrise
{
    [self.locationManager startUpdatingLocation];
    [self.locationManager requestWhenInUseAuthorization];

    EDSunriseSet *sunriseSet = [EDSunriseSet sunrisesetWithDate:[NSDate date]
                                                       timezone:[NSTimeZone localTimeZone]
                                                       latitude:self.locationManager.location.coordinate.latitude
                                                      longitude:self.locationManager.location.coordinate.longitude];
    self.sunrise = sunriseSet.localSunrise;
    self.sunset = sunriseSet.localSunset;

    [self.locationManager stopUpdatingLocation];
}

-(void)initiliazeTheme
{
    if ([self switchThemeBasedOnTime]) {
        return;
    }

    MCLThemeManager *themeManager = [MCLThemeManager sharedManager];
    NSUInteger themeName = [[NSUserDefaults standardUserDefaults] integerForKey:@"theme"];
    if (themeName == kMCLThemeNight) {
        [themeManager applyTheme:[[MCLNightTheme alloc] init]];
    } else {
        [themeManager applyTheme:[[MCLDefaultTheme alloc] init]];
    }
}

-(BOOL)switchThemeBasedOnTime
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"nightModeAutomatically"]) {
        return NO;
    }

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    MCLThemeManager *themeManager = [MCLThemeManager sharedManager];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *now = [calendar components:NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond
                                        fromDate:[NSDate date]];

    // --------------------
    NSLog(@"sunrise: %@", self.sunrise);
    NSLog(@"now: %@", now);
    NSLog(@"sunset: %@", self.sunset);
    // --------------------

    if (now.hour >= self.sunrise.hour && now.minute >= self.sunrise.minute && now.second >= self.sunrise.second) {
        if ([userDefaults integerForKey:@"theme"] != kMCLThemeDefault) {
            [themeManager applyTheme:[[MCLDefaultTheme alloc] init]];
            [userDefaults setInteger:kMCLThemeDefault forKey:@"theme"];

            return YES;
        }
    }

    if (now.hour >= self.sunset.hour && now.minute >= self.sunset.minute && now.second >= self.sunset.second) {
        if ([userDefaults integerForKey:@"theme"] != kMCLThemeNight) {
            [themeManager applyTheme:[[MCLNightTheme alloc] init]];
            [userDefaults setInteger:kMCLThemeNight forKey:@"theme"];

            return YES;
        }
    }

    return NO;
}

@end

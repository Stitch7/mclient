//
//  MCLThemeManager.m
//  mclient
//
//  Created by Christopher Reitz on 11/01/2017.
//  Copyright © 2017 Christopher Reitz. All rights reserved.
//

#import "MCLThemeManager.h"

#import <CoreLocation/CoreLocation.h>
#import <WebKit/WebKit.h>

#import "EDSunriseSet.h"

#import "MCLTheme.h"
#import "MCLDefaultTheme.h"
#import "MCLNightTheme.h"
#import "MCLDetailView.h"
#import "MCLLoadingView.h"
#import "MCLErrorView.h"
#import "MCLReadSymbolView.h"
#import "MCLBadgeView.h"

NSString * const MCLThemeChangedNotification = @"ThemeChangedNotification";

@interface MCLThemeManager()

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSDateComponents *sunrise;
@property (strong, nonatomic) NSDateComponents *sunset;

@end


@implementation MCLThemeManager

#pragma mark Initializers

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initiliazeLocationManager];
        [self updateSun];
    }
    return self;
}

+ (id)sharedManager
{
    static MCLThemeManager *sharedThemeManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedThemeManager = [[self alloc] init];
    });

    return sharedThemeManager;
}

#pragma mark Sunset

- (void)initiliazeLocationManager
{
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
}

- (BOOL)isAfterSunset:(NSDateComponents*)dateComponents
{
    if (dateComponents.hour > self.sunset.hour) {
        return YES;
    }

    if (dateComponents.hour == self.sunset.hour &&
        dateComponents.minute > self.sunset.minute
        ) {
        return YES;
    }

    if (dateComponents.hour == self.sunset.hour &&
        dateComponents.minute == self.sunset.minute &&
        dateComponents.second >= self.sunset.second
    ) {
        return YES;
    }

    return NO;
}

- (BOOL)isBeforeSunrise:(NSDateComponents*)dateComponents
{
    if (dateComponents.hour < self.sunrise.hour) {
        return YES;
    }

    if (dateComponents.hour == self.sunrise.hour &&
        dateComponents.minute < self.sunrise.minute
    ) {
        return YES;
    }

    if (dateComponents.hour == self.sunrise.hour &&
        dateComponents.minute == self.sunrise.minute &&
        dateComponents.second <= self.sunrise.second
        ) {
        return YES;
    }
    
    return NO;
}

#pragma mark Public

- (void)updateSun
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"nightModeAutomatically"]) {
        return;
    }

    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        self.sunrise = [[NSDateComponents alloc] init];
        self.sunrise.hour = 8;
        self.sunrise.minute = 0;
        self.sunrise.second = 0;

        self.sunset = [[NSDateComponents alloc] init];
        self.sunset.hour = 20;
        self.sunset.minute = 0;
        self.sunset.second = 0;
    }
    else {
        [self.locationManager startUpdatingLocation];
        [self.locationManager requestWhenInUseAuthorization];

        double latitude = self.locationManager.location.coordinate.latitude;
        double longitude = self.locationManager.location.coordinate.longitude;
        EDSunriseSet *sunriseSet = [EDSunriseSet sunrisesetWithDate:[NSDate date]
                                                           timezone:[NSTimeZone localTimeZone]
                                                           latitude:latitude
                                                          longitude:longitude];
        self.sunrise = sunriseSet.localSunrise;
        self.sunset = sunriseSet.localSunset;

        [self.locationManager stopUpdatingLocation];
    }
}

- (void)switchThemeBasedOnTime
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"nightModeAutomatically"]) {
        return;
    }

    MCLThemeManager *themeManager = [MCLThemeManager sharedManager];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *now = [calendar components:NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond
                                        fromDate:[NSDate date]];

    id <MCLTheme> theme;
    if ([self isAfterSunset:now] || [self isBeforeSunrise:now]) {
        theme = [[MCLNightTheme alloc] init];
    } else {
        theme = [[MCLDefaultTheme alloc] init];
    }
    [themeManager applyTheme:theme];
}

- (void)applyTheme: (id <MCLTheme>)theme
{
    if ([self.currentTheme description] == [theme description]) {
        return;
    }

    self.currentTheme = theme;

    UIBarStyle barStyle = [theme isDark] ? UIBarStyleBlack : UIBarStyleDefault;
    [[UINavigationBar appearance] setBarStyle:barStyle];

    [[UILabel appearance] setTextColor:[theme textColor]];

    [[UINavigationBar appearance] setBarTintColor:[theme navigationBarBackgroundColor]];
    [[UINavigationBar appearance] setTranslucent:YES];
    [[UINavigationBar appearance] setAlpha:0.7f];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [theme navigationBarTextColor]}];

    [[UIToolbar appearance] setBarTintColor:[theme toolbarBackgroundColor]];
    [[UIToolbar appearance] setTintColor:[theme tintColor]];

    [[UITableView appearance] setBackgroundColor:[theme tableViewBackgroundColor]];
    [[UITableView appearance] setSeparatorColor:[theme tableViewSeparatorColor]];

    [[UIRefreshControl appearance] setBackgroundColor:[theme refreshControlBackgroundColor]];

    [[UISearchBar appearance] setBackgroundImage:[[UIImage alloc] init]];
    [[UISearchBar appearance] setBackgroundColor:[theme searchBarBackgroundColor]];

    [[UITableViewCell appearance] setBackgroundColor:[theme tableViewCellBackgroundColor]];
    [[UILabel appearanceWhenContainedInInstancesOfClasses:@[[UITableViewCell class]]] setTextColor:[theme textColor]];

    [[MCLDetailView appearance] setBackgroundColor:[theme backgroundColor]];
    [[UILabel appearanceWhenContainedInInstancesOfClasses:@[[MCLDetailView class]]] setTextColor:[theme overlayTextColor]];

    [[MCLLoadingView appearance] setBackgroundColor:[theme backgroundColor]];
    [[UILabel appearanceWhenContainedInInstancesOfClasses:@[[MCLLoadingView class]]] setTextColor:[theme overlayTextColor]];

    [[MCLErrorView appearance] setBackgroundColor:[theme backgroundColor]];
    [[UILabel appearanceWhenContainedInInstancesOfClasses:@[[MCLErrorView class]]] setTextColor:[theme overlayTextColor]];

    [[MCLBadgeView appearance] setBackgroundColor:[theme badgeViewBackgroundColor]];

    [[MCLReadSymbolView appearance] setColor:[theme tintColor]];

    UIActivityIndicatorViewStyle indicatorViewStyle = [theme isDark]
        ? UIActivityIndicatorViewStyleWhite
        : UIActivityIndicatorViewStyleGray;
    [[UIActivityIndicatorView appearance] setActivityIndicatorViewStyle:indicatorViewStyle];

    [[UITextView appearance] setBackgroundColor:[theme textViewBackgroundColor]];

    UIKeyboardAppearance keyboardAppearance = [theme isDark] ? UIKeyboardAppearanceDark : UIKeyboardAppearanceLight;
    [[UITextField appearance] setKeyboardAppearance:keyboardAppearance];
    [[UITextField appearance] setTextColor:[theme textViewTextColor]];

    [[UIWebView appearance] setBackgroundColor:[theme webViewBackgroundColor]];
    [[WKWebView appearance] setBackgroundColor:[theme webViewBackgroundColor]];
    [[UIScrollView appearanceWhenContainedInInstancesOfClasses:@[[WKWebView class]]] setBackgroundColor:[theme webViewBackgroundColor]];

    [[NSUserDefaults standardUserDefaults] setInteger:[theme identifier] forKey:@"theme"];

    NSArray *windows = [UIApplication sharedApplication].windows;
    for (UIWindow *window in windows) {
        for (UIView *view in window.subviews) {
            [view removeFromSuperview];
            [window addSubview:view];
        }
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:MCLThemeChangedNotification object:self];
}

@end

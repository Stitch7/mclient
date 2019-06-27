//
//  UIApplication+Additions.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "UIApplication+Additions.h"

@implementation UIApplication (Additions)

- (NSString *)version
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

- (NSString *)buildNumber
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}

- (NSInteger)incrementApplicationIconBadgeNumber
{
    if (self.applicationIconBadgeNumber < 0) {
        self.applicationIconBadgeNumber = 0;
    }
    self.applicationIconBadgeNumber += 1;

    return self.applicationIconBadgeNumber;
}

- (NSInteger)decrementApplicationIconBadgeNumber
{
    if (self.applicationIconBadgeNumber > 0) {
        self.applicationIconBadgeNumber -= 1;
    }

    return self.applicationIconBadgeNumber;
}

- (BOOL)isYoutubeAppInstalled
{
    return [self canOpenURL:[NSURL URLWithString:@"youtube://"]];
}

- (void)quit
{
    // Press home button programmatically
    [self performSelector:@selector(suspend)];

    // Wait 2 seconds while app is going background
    [NSThread sleepForTimeInterval:2.0];

    // Exit app when app is in background
    exit(0);
}

@end

//
//  UIApplication+Additions.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "UIApplication+Additions.h"

@implementation UIApplication (Additions)

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

@end

//
//  UIApplication+Additions.m
//  mclient
//
//  Created by Christopher Reitz on 11/03/2017.
//  Copyright © 2017 Christopher Reitz. All rights reserved.
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

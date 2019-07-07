//
//  UIDevice+deviceName.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "UIDevice+deviceName.h"

#import <sys/utsname.h>

@implementation UIDevice (deviceName)

- (NSString *)deviceName
{
    struct utsname systemInfo;
    uname(&systemInfo);

    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}

@end

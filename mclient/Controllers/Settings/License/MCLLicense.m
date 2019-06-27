//
//  MCLLicense.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLLicense.h"


@implementation MCLLicense

+ (instancetype)licenseWithName:(NSString *)name andText:(NSString *)text
{
    MCLLicense *license = [[MCLLicense alloc] init];
    license.name = name;
    license.text = text;

    return license;
}

@end

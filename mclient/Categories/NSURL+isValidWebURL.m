//
//  NSURL+isValidWebURL.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "NSURL+isValidWebURL.h"


@implementation NSURL (isValidWebURL)

- (BOOL)isValidWebURL
{
    NSString *urlString = self.absoluteString.lowercaseString;
    if ([urlString hasPrefix:@"http"] || [urlString hasPrefix:@"https"]) {
        return YES;
    }

    return NO;
}

@end

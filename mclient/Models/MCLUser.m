//
//  MCLUser.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLUser.h"

@implementation MCLUser

+ (MCLUser *)userWithId:(NSNumber *)inUserId username:(NSString *)inUsername
{
    MCLUser *user = [[MCLUser alloc] init];
    
    user.userId = inUserId;
    user.username = inUsername;

    return user;
}

+ (MCLUser *)userFromJSON:(NSDictionary *)json
{
    MCLUser *user = [[MCLUser alloc] init];

    user.userId = [json objectForKey:@"userId"];
    user.username = [json objectForKey:@"username"];

    return user;
}

@end

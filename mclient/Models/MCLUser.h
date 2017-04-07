//
//  MCLUser.h
//  mclient
//
//  Copyright © 2014 - 2017 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@interface MCLUser : NSObject

@property (strong) NSNumber *userId;
@property (strong) NSString *username;

+ (MCLUser *)userWithId:(NSNumber *)inUserId username:(NSString *)inUsername;

@end

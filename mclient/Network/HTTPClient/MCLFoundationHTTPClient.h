//
//  MCLFoundationHTTPClient.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLHTTPClient.h"


@class MCLLogin;

@interface MCLFoundationHTTPClient : NSObject <MCLHTTPClient>

- (instancetype)initWithLogin:(MCLLogin *)login;

@end

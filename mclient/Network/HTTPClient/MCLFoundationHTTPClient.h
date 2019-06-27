//
//  MCLFoundationHTTPClient.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLHTTPClient.h"


@class MCLLoginManager;

@interface MCLFoundationHTTPClient : NSObject <MCLHTTPClient>

- (instancetype)initWithLoginManager:(MCLLoginManager *)loginManager;

@end

//
//  MCLFavoriteThreadToggleRequest.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLRequest.h"

@protocol MCLHTTPClient;
@class MCLThread;

@interface MCLFavoriteThreadToggleRequest : NSObject <MCLRequest>

@property (assign, nonatomic) BOOL forceRemove;

- (instancetype)initWithClient:(id <MCLHTTPClient>)httpClient thread:(MCLThread *)thread;

@end

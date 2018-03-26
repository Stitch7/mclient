//
//  MCLThreadListRequest.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLRequest.h"


@protocol MCLHTTPClient;
@class MCLBoard;
@class MCLLogin;

@interface MCLThreadListRequest : NSObject <MCLRequest>

- (instancetype)initWithClient:(id <MCLHTTPClient>)httpClient board:(MCLBoard *)board login:(MCLLogin *)login;
- (void)loadWithCompletionHandler:(void (^)(NSError*, NSArray*))completionHandler;

@end

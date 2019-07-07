//
//  MCLThreadListRequest.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLRequest.h"


@protocol MCLHTTPClient;
@class MCLBoard;
@class MCLLoginManager;

@interface MCLThreadListRequest : NSObject <MCLRequest>

- (instancetype)initWithClient:(id <MCLHTTPClient>)httpClient board:(MCLBoard *)board loginManager:(MCLLoginManager *)loginManager;
- (void)loadWithCompletionHandler:(void (^)(NSError*, NSArray*))completionHandler;

@end

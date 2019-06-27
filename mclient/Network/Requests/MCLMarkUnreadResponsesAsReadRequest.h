//
//  MCLMarkUnreadResponsesAsReadRequest.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLRequest.h"

@protocol MCLHTTPClient;
@class MCLLoginManager;

@interface MCLMarkUnreadResponsesAsReadRequest : NSObject <MCLRequest>

- (instancetype)initWithClient:(id <MCLHTTPClient>)httpClient loginManager:(MCLLoginManager *)loginManager;

@end

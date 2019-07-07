//
//  MCLMessageResponsesRequest.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLResponseContainer.h"
#import "MCLRequest.h"

extern NSString * const MCLUnreadResponsesFoundNotification;

@protocol MCLDependencyBag;
@protocol MCLHTTPClient;

@interface MCLMessageResponsesRequest : NSObject <MCLRequest>

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag;
- (void)loadResponsesWithCompletion:(void (^)(NSError *error, MCLResponseContainer *responseContainer))completion;
- (void)loadUnreadResponsesWithCompletion:(void (^)(NSError *error, NSArray *unreadResponses))completion;

@end

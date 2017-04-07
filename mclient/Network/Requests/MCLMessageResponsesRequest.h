//
//  MCLMessageResponsesRequest.h
//  mclient
//
//  Copyright © 2014 - 2017 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLResponseContainer.h"

extern NSString * const MCLUnreadResponsesFoundNotification;

@protocol MCLDependencyBag;

@interface MCLMessageResponsesRequest : NSObject

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag;
- (void)loadResponsesWithCompletion:(void (^)(NSError *error, MCLResponseContainer *responseContainer))completion;
- (void)loadUnreadResponsesWithCompletion:(void (^)(NSError *error, NSArray *unreadResponses))completion;

@end

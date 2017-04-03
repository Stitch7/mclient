//
//  MCLMessageResponsesClient.h
//  mclient
//
//  Created by Christopher Reitz on 28/02/2017.
//  Copyright © 2017 Christopher Reitz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCLResponseContainer.h"

extern NSString * const MCLMessageResponsesClientFoundUnreadResponsesNotification;

@interface MCLMessageResponsesClient : NSObject

+ (id)sharedClient;
- (void)loadResponsesWithCompletion:(void (^)(NSError *error, MCLResponseContainer *responseContainer))completion;
- (void)loadUnreadResponsesWithCompletion:(void (^)(NSError *error, NSArray *unreadResponses))completion;

@end

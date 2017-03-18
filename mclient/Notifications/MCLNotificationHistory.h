//
//  MCLNotificationHistory.h
//  mclient
//
//  Created by Christopher Reitz on 11/03/2017.
//  Copyright © 2017 Christopher Reitz. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MCLResponse;

@interface MCLNotificationHistory : NSObject

+ (id)sharedNotificationHistory;

- (void)addResponse:(MCLResponse *)response;
- (void)removeResponse:(MCLResponse *)response;
- (void)removeMessageId:(NSNumber *)messageId;
- (BOOL)responseWasAlreadyPresented:(MCLResponse *)response;

@end

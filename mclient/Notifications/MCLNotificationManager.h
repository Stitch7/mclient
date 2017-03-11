//
//  MCLNotificationManager.h
//  mclient
//
//  Created by Christopher Reitz on 11/03/2017.
//  Copyright © 2017 Christopher Reitz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCLNotificationHistory.h"

@interface MCLNotificationManager : NSObject

+ (id)sharedNotificationManager;

- (void)sendLocalNotificationForResponse:(MCLResponse *)response;

@property (strong, nonatomic) MCLNotificationHistory *notificationHistory;

@end

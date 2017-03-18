//
//  MCLNotificationManager.h
//  mclient
//
//  Created by Christopher Reitz on 11/03/2017.
//  Copyright © 2017 Christopher Reitz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCLResponse.h"

@interface MCLNotificationManager : NSObject

+ (id)sharedNotificationManager;
- (void)sendLocalNotificationForResponse:(MCLResponse *)response;

@end

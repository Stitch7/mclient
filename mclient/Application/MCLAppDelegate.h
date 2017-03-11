//
//  MCLAppDelegate.h
//  mclient
//
//  Created by Christopher Reitz on 21.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "MCLNotificationManager.h"

@interface MCLAppDelegate : UIResponder <UIApplicationDelegate> {
    SystemSoundID _notificationSound;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UIAlertView *notificationAlert;
@property (strong, nonatomic) MCLNotificationManager *notificationManager;

@end

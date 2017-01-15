//
//  MCLAppDelegate.h
//  mclient
//
//  Created by Christopher Reitz on 21.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface MCLAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSDateComponents *sunrise;
@property (strong, nonatomic) NSDateComponents *sunset;

@end

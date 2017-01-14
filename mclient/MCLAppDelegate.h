//
//  MCLAppDelegate.h
//  mclient
//
//  Created by Christopher Reitz on 21.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MCLAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) NSDate *sunrise;
@property (strong, nonatomic) NSDate *sunset;

@end

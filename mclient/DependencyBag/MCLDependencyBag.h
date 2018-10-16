//
//  MCLDependencyBag.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@class MCLFeatures;
@class MCLLogin;
@class MCLRouter;
@class MCLNotificationManager;
@class MCLSettings;
@class MCLThemeManager;
@class MCLSoundEffectPlayer;
@protocol MCLHTTPClient;

@protocol MCLDependencyBag <NSObject>

@property (strong, nonatomic) MCLFeatures *features;
@property (strong, nonatomic) MCLLogin *login;
@property (strong, nonatomic) MCLRouter *router;
@property (strong, nonatomic) MCLNotificationManager *notificationManager;
@property (strong, nonatomic) MCLSettings *settings;
@property (strong, nonatomic) MCLThemeManager *themeManager;
@property (strong, nonatomic) MCLSoundEffectPlayer *soundEffectPlayer;
@property (strong, nonatomic) id <MCLHTTPClient> httpClient;

- (void)launchRootWindow:(void (^)(UIWindow *window))windowHandler;

@end

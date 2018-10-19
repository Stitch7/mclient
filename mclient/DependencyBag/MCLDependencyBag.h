//
//  MCLDependencyBag.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@class MCLFeatures;
@class MCLLoginManager;
@class MCLRouter;
@class MCLNotificationManager;
@class MCLSettings;
@class MCLThemeManager;
@class MCLSoundEffectPlayer;
@class MCLStoreReviewManager;
@protocol MCLHTTPClient;

@protocol MCLDependencyBag <NSObject>

@property (strong, nonatomic) MCLFeatures *features;
@property (strong, nonatomic) MCLLoginManager *loginManager;
@property (strong, nonatomic) MCLRouter *router;
@property (strong, nonatomic) MCLNotificationManager *notificationManager;
@property (strong, nonatomic) MCLSettings *settings;
@property (strong, nonatomic) MCLThemeManager *themeManager;
@property (strong, nonatomic) MCLSoundEffectPlayer *soundEffectPlayer;
@property (strong, nonatomic) MCLStoreReviewManager *storeReviewManager;
@property (strong, nonatomic) id <MCLHTTPClient> httpClient;

- (void)launchRootWindow:(void (^)(UIWindow *window))windowHandler;

@end

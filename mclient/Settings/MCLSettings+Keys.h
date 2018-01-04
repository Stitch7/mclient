//
//  MCLSettings.h
//  mclient
//
//  Copyright © 2014 - 2017 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

extern NSString *const MCLSettingNightModeEnabled;
extern NSString *const MCLSettingNightModeAutomatically;
extern NSString *const MCLSettingShowImages;
extern NSString *const MCLSettingThreadView;
extern NSString *const MCLSettingJumpToLatestPost;
extern NSString *const MCLSettingSignatureEnabled;
extern NSString *const MCLSettingSignatureText;
extern NSString *const MCLSettingFontSize;
extern NSString *const MCLSettingTheme;
extern NSString *const MCLSettingOpenLinksInSafari;
extern NSString *const MCLSettingBackgroundNotifications;

typedef NS_ENUM(NSUInteger, kMCLSettingsThreadView) {
    kMCLSettingsThreadViewWidmann,
    kMCLSettingsThreadViewFrame
};

typedef NS_ENUM(NSUInteger, kMCLSettingsShowImages) {
    kMCLSettingsShowImagesAlways,
    kMCLSettingsShowImagesWifi,
    kMCLSettingsShowImagesNever
};
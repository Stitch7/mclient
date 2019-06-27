//
//  MCLSettings.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//


extern NSString *const MCLSettingInitialReportSend;
extern NSString *const MCLSettingNumberOfTimesLaunched;
extern NSString *const MCLSettingLastAppVersion;
extern NSString *const MCLSettingDarkModeEnabled;
extern NSString *const MCLSettingDarkModeAutomatically;
extern NSString *const MCLSettingShowImages;
extern NSString *const MCLSettingThreadView;
extern NSString *const MCLSettingJumpToLatestPost;
extern NSString *const MCLSettingSignatureEnabled;
extern NSString *const MCLSettingSignatureText;
extern NSString *const MCLSettingFontSize;
extern NSString *const MCLSettingTheme;
extern NSString *const MCLSettingOpenLinksInSafari;
extern NSString *const MCLSettingClassicQuoteDesign;
extern NSString *const MCLSettingEmbedYoutubeVideos;
extern NSString *const MCLSettingBackgroundNotifications;
extern NSString *const MCLSettingBackgroundNotificationsRegistered;
extern NSString *const MCLSettingSoundEffectsEnabled;
extern NSString *const MCLSettingHideFavoritesHint;
extern NSString *const MCLSettingSecretFound;

typedef NS_ENUM(NSUInteger, kMCLSettingsThreadView) {
    kMCLSettingsThreadViewWidmann,
    kMCLSettingsThreadViewFrame
};

typedef NS_ENUM(NSUInteger, kMCLSettingsShowImages) {
    kMCLSettingsShowImagesAlways,
    kMCLSettingsShowImagesWifi,
    kMCLSettingsShowImagesNever
};

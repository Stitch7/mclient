//
//  MCLThemeManager.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

extern NSString * const MCLThemeChangedNotification;

typedef NS_ENUM(NSUInteger, kMCLTheme) {
    kMCLThemeLight,
    kMCLThemeDark
};

@protocol MCLTheme;
@class MCLSettings;

@interface MCLThemeManager : NSObject

@property (strong, nonatomic) id <MCLTheme> currentTheme;

- (instancetype)initWithSettings:(MCLSettings *)settings;

- (void)updateSun;
- (void)loadTheme;
- (void)applyTheme:(id <MCLTheme>)theme;

@end

//
//  MCLSettings.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLSettings.h"


@interface MCLSettings()

@property (strong, nonatomic) NSUserDefaults *userDefaults;

@end

@implementation MCLSettings

#pragma mark - Initializer

- (instancetype)initWithUserDefaults:(NSUserDefaults *)userDefaults
{
    self = [super init];
    if (!self) return nil;

    self.userDefaults = userDefaults;

    return self;
}

#pragma mark - Public

- (void)setBool:(BOOL)value forSetting:(NSString *)setting
{
    [self.userDefaults setBool:value forKey:setting];
    [self persist];
}

- (void)setValue:(id)value forSetting:(NSString *)setting
{
    [self.userDefaults setValue:value forKey:setting];
    [self persist];
}

- (BOOL)isSettingActivated:(NSString *)setting
{
    return [self.userDefaults boolForKey:setting];
}

- (BOOL)isSettingActivated:(NSString *)setting orDefault:(BOOL)defaultValue
{
    if ([self objectForSetting:setting]) {
        return [self isSettingActivated:setting];
    }

    return defaultValue;
}

- (NSInteger)integerForSetting:(NSString *)setting
{
    return [self.userDefaults integerForKey:setting];
}

- (NSInteger)integerForSetting:(NSString *)setting orDefault:(NSInteger)defaultValue
{
    if ([self objectForSetting:setting]) {
        return [self.userDefaults integerForKey:setting];
    }

    return defaultValue;
}

- (void)setInteger:(NSInteger)value forSetting:(NSString *)setting
{
    [self.userDefaults setInteger:value forKey:setting];
    [self persist];
}

- (NSNumber *)numberForSetting:(NSString *)setting
{
    return @([self.userDefaults integerForKey:setting]);
}

- (NSNumber *)numberForSetting:(NSString *)setting orDefault:(NSInteger)defaultValue
{
    if ([self objectForSetting:setting]) {
        return @([self.userDefaults integerForKey:setting]);
    }

    return @(defaultValue);
}

- (id)objectForSetting:(NSString *)setting
{
    return [self.userDefaults objectForKey:setting];
}

- (id)objectForSetting:(NSString *)setting orDefault:(id)defaultValue
{
    return [self objectForSetting:setting] ?: defaultValue;
}

- (void)setObject:(id)object forSetting:(NSString *)setting
{
    [self.userDefaults setObject:object forKey:setting];
    [self persist];
}

- (NSDictionary *)dictionaryWithAllSettings
{
    return @{MCLSettingNumberOfTimesLaunched:   [self numberForSetting:MCLSettingNumberOfTimesLaunched orDefault:0],
             MCLSettingLastAppVersion:          [self objectForSetting:MCLSettingLastAppVersion orDefault:@""],
             MCLSettingDarkModeEnabled:         [self stringForIsSettingActivated:MCLSettingDarkModeEnabled],
             MCLSettingDarkModeAutomatically:   [self stringForIsSettingActivated:MCLSettingDarkModeAutomatically],
             MCLSettingShowImages:              [self numberForSetting:MCLSettingShowImages],
             MCLSettingThreadView:              [self numberForSetting:MCLSettingThreadView],
             MCLSettingJumpToLatestPost:        [self stringForIsSettingActivated:MCLSettingJumpToLatestPost],
             MCLSettingSignatureEnabled:        [self stringForIsSettingActivated:MCLSettingSignatureEnabled orDefault:YES],
             MCLSettingSignatureText:           [self objectForSetting:MCLSettingSignatureText orDefault:kSettingsSignatureTextDefault],
             MCLSettingFontSize:                [self numberForSetting:MCLSettingFontSize orDefault:kSettingsDefaultFontSize],
             MCLSettingTheme:                   [self numberForSetting:MCLSettingTheme orDefault:0],
             MCLSettingOpenLinksInSafari:       [self stringForIsSettingActivated:MCLSettingOpenLinksInSafari],
             MCLSettingClassicQuoteDesign:      [self stringForIsSettingActivated:MCLSettingClassicQuoteDesign],
             MCLSettingBackgroundNotifications: [self stringForIsSettingActivated:MCLSettingBackgroundNotifications],
             MCLSettingSoundEffectsEnabled:     [self stringForIsSettingActivated:MCLSettingSoundEffectsEnabled orDefault:YES]};
}

#pragma mark - Private

- (NSString *)stringForIsSettingActivated:(NSString *)setting
{
    return [self isSettingActivated:setting] ? @"true" : @"false";
}

- (NSString *)stringForIsSettingActivated:(NSString *)setting orDefault:(BOOL)defaultValue
{
    BOOL isActivated = defaultValue;
    if ([self objectForSetting:setting]) {
        isActivated = [self isSettingActivated:setting];
    }

    return isActivated ? @"true" : @"false";
}

- (BOOL)persist
{
    return [self.userDefaults synchronize];
}

@end

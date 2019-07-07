//
//  MCLSettings.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLSettings.h"
#import "MCLSettings+Keys.h"

#import "TargetConditionals.h"

#import "UIDevice+deviceName.h"
#import "MCLDependencyBag.h"
#import "MCLLoginManager.h"
#import "MCLSendSettingsRequest.h"


@interface MCLSettings()

@property (strong, nonatomic) id <MCLDependencyBag> bag;
@property (strong, nonatomic) NSUserDefaults *userDefaults;
@property (assign, nonatomic, getter=wereChanged) BOOL changed;

@end

@implementation MCLSettings

#pragma mark - Initializer

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag userDefaults:(NSUserDefaults *)userDefaults
{
    self = [super init];
    if (!self) return nil;

    self.bag = bag;
    self.userDefaults = userDefaults;
    self.changed = NO;
    [self configureDefaultSettings];

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
    return @{@"deviceName":                     [[UIDevice currentDevice] deviceName],
             MCLSettingNumberOfTimesLaunched:   [self numberForSetting:MCLSettingNumberOfTimesLaunched orDefault:0],
             MCLSettingLastAppVersion:          [self objectForSetting:MCLSettingLastAppVersion orDefault:@""],
             MCLSettingDarkModeEnabled:         [self jsonForIsSettingActivated:MCLSettingDarkModeEnabled],
             MCLSettingDarkModeAutomatically:   [self jsonForIsSettingActivated:MCLSettingDarkModeAutomatically],
             MCLSettingShowImages:              [self numberForSetting:MCLSettingShowImages],
             MCLSettingThreadView:              [self numberForSetting:MCLSettingThreadView],
             MCLSettingJumpToLatestPost:        [self jsonForIsSettingActivated:MCLSettingJumpToLatestPost],
             MCLSettingSignatureEnabled:        [self jsonForIsSettingActivated:MCLSettingSignatureEnabled orDefault:YES],
             MCLSettingSignatureText:           [self objectForSetting:MCLSettingSignatureText orDefault:kSettingsSignatureTextDefault],
             MCLSettingFontSize:                [self numberForSetting:MCLSettingFontSize orDefault:kSettingsDefaultFontSize],
             MCLSettingTheme:                   [self numberForSetting:MCLSettingTheme orDefault:0],
             MCLSettingOpenLinksInSafari:       [self jsonForIsSettingActivated:MCLSettingOpenLinksInSafari],
             MCLSettingEmbedYoutubeVideos:      [self jsonForIsSettingActivated:MCLSettingEmbedYoutubeVideos],
             MCLSettingClassicQuoteDesign:      [self jsonForIsSettingActivated:MCLSettingClassicQuoteDesign],
             MCLSettingBackgroundNotifications: [self jsonForIsSettingActivated:MCLSettingBackgroundNotifications],
             MCLSettingSoundEffectsEnabled:     [self jsonForIsSettingActivated:MCLSettingSoundEffectsEnabled orDefault:YES]};
}

- (void)reportSettingsIfChanged
{
    if (self.wereChanged) {
        [self reportSettings];
    }
}

#pragma mark - Private

- (void)configureDefaultSettings
{
    if ([self objectForSetting:MCLSettingEmbedYoutubeVideos] == nil) {
        [self setBool:YES forSetting:MCLSettingEmbedYoutubeVideos];
    }

    if ([self objectForSetting:MCLSettingBackgroundNotificationsRegistered] == nil) {
        [self setBool:NO forSetting:MCLSettingBackgroundNotificationsRegistered];
    }

    // TODO: configure others

    [self persist];
}

- (NSNumber *)jsonForIsSettingActivated:(NSString *)setting
{
    return [self isSettingActivated:setting] ? @YES : @NO;
}

- (NSNumber *)jsonForIsSettingActivated:(NSString *)setting orDefault:(BOOL)defaultValue
{
    BOOL isActivated = defaultValue;
    if ([self objectForSetting:setting]) {
        isActivated = [self isSettingActivated:setting];
    }

    return isActivated ? @YES : @NO;
}

- (BOOL)persist
{
    self.changed = YES;
    return [self.userDefaults synchronize];
}

- (void)reportSettings
{
#if TARGET_OS_SIMULATOR
    return;
#else
    if (!self.bag.loginManager.isLoginValid) {
        return;
    }

    NSString *uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    MCLSendSettingsRequest *request = [[MCLSendSettingsRequest alloc] initWithClient:self.bag.httpClient
                                                                                uuid:uuid
                                                                            settings:self];
    [request loadWithCompletionHandler:^(NSError *error, NSArray *response) {
        if (error) {
            return;
        }
        [self setBool:YES forSetting:MCLSettingInitialReportSend];
        self.changed = NO;
    }];
#endif
}

@end

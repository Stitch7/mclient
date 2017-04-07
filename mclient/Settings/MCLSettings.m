//
//  MCLSettings.m
//  mclient
//
//  Copyright © 2014 - 2017 Christopher Reitz. Licensed under the MIT license.
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

- (void)setInteger:(NSInteger)value forSetting:(NSString *)setting
{
    [self.userDefaults setInteger:value forKey:setting];
    [self persist];
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

#pragma mark - Private

- (BOOL)persist
{
    return [self.userDefaults synchronize];
}

@end

//
//  MCLSettings.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLSettings+Keys.h"

@protocol MCLDependencyBag;

@interface MCLSettings : NSObject

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag userDefaults:(NSUserDefaults *)userDefaults;

- (void)setBool:(BOOL)value forSetting:(NSString *)setting;
- (void)setValue:(id)value forSetting:(NSString *)setting;
- (BOOL)isSettingActivated:(NSString *)setting;
- (BOOL)isSettingActivated:(NSString *)setting orDefault:(BOOL)defaultValue;
- (NSInteger)integerForSetting:(NSString *)setting;
- (NSInteger)integerForSetting:(NSString *)setting orDefault:(NSInteger)defaultValue;
- (void)setInteger:(NSInteger)value forSetting:(NSString *)setting;
- (NSNumber *)numberForSetting:(NSString *)setting;
- (NSNumber *)numberForSetting:(NSString *)setting orDefault:(NSInteger)defaultValue;
- (id)objectForSetting:(NSString *)setting;
- (id)objectForSetting:(NSString *)setting orDefault:(id)defaultValue;
- (void)setObject:(id)object forSetting:(NSString *)setting;
- (NSDictionary *)dictionaryWithAllSettings;
- (void)reportSettingsIfChanged;

- (void)reportSettings;

@end

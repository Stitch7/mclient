//
//  MCLSettings.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLSettings+Keys.h"

@interface MCLSettings : NSObject

- (instancetype)initWithUserDefaults:(NSUserDefaults *)userDefaults;

- (void)setBool:(BOOL)value forSetting:(NSString *)setting;
- (void)setValue:(id)value forSetting:(NSString *)setting;
- (BOOL)isSettingActivated:(NSString *)setting;
- (BOOL)isSettingActivated:(NSString *)setting orDefault:(BOOL)defaultValue;
- (NSInteger)integerForSetting:(NSString *)setting;
- (void)setInteger:(NSInteger)value forSetting:(NSString *)setting;
- (id)objectForSetting:(NSString *)setting;
- (id)objectForSetting:(NSString *)setting orDefault:(id)defaultValue;
- (void)setObject:(id)object forSetting:(NSString *)setting;

@end

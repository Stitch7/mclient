//
//  MCLStoreReviewManager.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLStoreReviewManager.h"

#import "UIApplication+Additions.h"
#import "MCLSettings.h"

@import StoreKit;


#define kAppropriateLaunchesWithoutAsking 5

@interface MCLStoreReviewManager ()

@property (strong, nonatomic) MCLSettings *settings;

@end

@implementation MCLStoreReviewManager

#pragma mark - Initializers

- (instancetype)initWithSettings:(MCLSettings *)settings
{
    self = [super init];
    if (!self) return nil;

    self.settings = settings;
    [self incrementNumberOfTimesLaunched];

    return self;
}

#pragma mark - Private

- (NSInteger)numberOfTimesLaunched
{
    return [self.settings integerForSetting:MCLSettingNumberOfTimesLaunched orDefault:0];
}

- (void)incrementNumberOfTimesLaunched
{
    NSInteger numberOfTimesLaunched = [self numberOfTimesLaunched];
    numberOfTimesLaunched++;
    [self.settings setInteger:numberOfTimesLaunched forSetting:MCLSettingNumberOfTimesLaunched];
}

- (BOOL)alreadyAsked:(NSString *)version
{
    NSString *lastVersionPromptedForReview = [self.settings objectForSetting:MCLSettingLastAppVersion orDefault:@""];
    return [version isEqualToString:lastVersionPromptedForReview];
}

#pragma mark - Public

- (void)promptForReviewIfAppropriate
{
    NSString *currentVersion = [[UIApplication sharedApplication] version];
    if ([self numberOfTimesLaunched] < kAppropriateLaunchesWithoutAsking || [self alreadyAsked:currentVersion]) {
        return;
    }

    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.3")) {
        [SKStoreReviewController requestReview];
        [self.settings setObject:currentVersion forSetting:MCLSettingLastAppVersion];
    }
}

@end

//
//  MCLNoDataInfo.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLNoDataInfo.h"

#import "MCLSettings.h"

@interface MCLNoDataInfo ()

@property (strong, nonatomic) MCLSettings *settings;
@property (strong, nonatomic, readwrite) NSString *messageText;
@property (assign, nonatomic, readwrite, getter=hasHelp) BOOL help;
@property (strong, nonatomic, readwrite) NSString *helpTitle;
@property (strong, nonatomic, readwrite) NSString *helpMessage;
@property (strong, nonatomic, readwrite) NSString *hideKey;

@end

@implementation MCLNoDataInfo

- (instancetype)initWithSettings:(MCLSettings *)settings messageText:(NSString *)messageText helpTitle:(NSString *)helpTitle helpMessage:(NSString *)helpMessage hideKey:(NSString *)hideKey
{
    self = [super init];
    if (!self) return nil;

    self.settings = settings;
    self.messageText = messageText;
    self.help = YES;
    self.helpTitle = helpTitle;
    self.helpMessage = helpMessage;
    self.hideKey = hideKey;

    return self;
}

- (instancetype)initWithMessageText:(NSString *)messageText
{
    self = [super init];
    if (!self) return nil;

    self.settings = nil;
    self.messageText = messageText;
    self.help = NO;
    self.helpTitle = nil;
    self.helpMessage = nil;
    self.hideKey = nil;

    return self;
}

+ (MCLNoDataInfo *)infoForLoginToSeeFavoritesInfo
{
    return [[self alloc] initWithMessageText:NSLocalizedString(@"PLEASE LOGIN TO SEE YOUR FAVORITES", nil)];
}

+ (MCLNoDataInfo *)infoForNoFavoritesInfo:(MCLSettings *)settings
{
    return [[self alloc] initWithSettings:settings
                              messageText:NSLocalizedString(@"NO FAVORITES", nil)
                                helpTitle:NSLocalizedString(@"favorites_help_title", nil)
                              helpMessage:NSLocalizedString(@"favorites_help_message", nil)
                                  hideKey:MCLSettingHideFavoritesHint];
}

+ (MCLNoDataInfo *)infoForNoSearchResultsInfo
{
    return [[self alloc] initWithMessageText:NSLocalizedString(@"NO RESULTS", nil)];
}

- (BOOL)isHidden
{
    return self.hideKey ? [self.settings isSettingActivated:self.hideKey] : NO;
}

- (void)hide
{
    if (!self.settings) {
        return;
    }

    [self.settings setBool:YES forSetting:self.hideKey];
}

@end

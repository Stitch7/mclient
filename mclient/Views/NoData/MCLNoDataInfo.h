//
//  MCLNoDataInfo.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@class MCLSettings;

@interface MCLNoDataInfo : NSObject

@property (strong, nonatomic, readonly) NSString *messageText;
@property (assign, nonatomic, readonly, getter=hasHelp) BOOL help;
@property (strong, nonatomic, readonly) NSString *helpTitle;
@property (strong, nonatomic, readonly) NSString *helpMessage;
@property (strong, nonatomic, readonly) NSString *hideKey;

- (instancetype)initWithSettings:(MCLSettings *)settings messageText:(NSString *)messageText helpTitle:(NSString *)helpTitle helpMessage:(NSString *)helpMessage hideKey:(NSString *)hideKey;
- (instancetype)initWithMessageText:(NSString *)messageText;

+ (MCLNoDataInfo *)infoForLoginToSeeFavoritesInfo;
+ (MCLNoDataInfo *)infoForNoFavoritesInfo:(MCLSettings *)settings;
+ (MCLNoDataInfo *)infoForNoSearchResultsInfo;

- (BOOL)isHidden;
- (void)hide;

@end

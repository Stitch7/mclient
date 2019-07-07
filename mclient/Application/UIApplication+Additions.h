//
//  UIApplication+Additions.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@interface UIApplication (Additions)

- (NSString *)version;
- (NSString *)buildNumber;
- (NSInteger)incrementApplicationIconBadgeNumber;
- (NSInteger)decrementApplicationIconBadgeNumber;
- (BOOL)isYoutubeAppInstalled;
- (void)quit;

@end

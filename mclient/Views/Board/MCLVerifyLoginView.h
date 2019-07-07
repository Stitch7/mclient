//
//  MCLVerifyLoginView.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@class MCLThemeManager;

@interface MCLVerifyLoginView : UIButton

- (instancetype)initWithThemeManager:(MCLThemeManager *)themeManager;

- (void)loginStatusWithUsername:(NSString *)username;
- (void)loginStatusNoLogin;
- (void)setNumberOfDrafts:(NSNumber *)numberOfDrafts;
- (void)setNumberOfDrafts:(NSNumber *)numberOfDrafts withDelay:(double)delayInSeconds;

@end




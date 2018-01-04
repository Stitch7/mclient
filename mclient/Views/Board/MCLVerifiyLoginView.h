//
//  MCLVerifiyLoginView.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLLoadingView.h"

@class MCLThemeManager;

@interface MCLVerifiyLoginView : MCLLoadingView

- (instancetype)initWithThemeManager:(MCLThemeManager *)themeManager;

- (void)loginStatusWithUsername:(NSString *)username;
- (void)loginStatusNoLogin;

@end

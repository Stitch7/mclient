//
//  MCLTheme.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLTheme <NSObject>

- (NSUInteger)identifier;
- (BOOL)isDark;
- (UIColor *)tintColor;
- (NSString *)cssTintColor;
- (NSString *)cssQuoteColor;
- (UIColor *)backgroundColor;
- (UIColor *)textColor;
- (UIColor *)detailTextColor;
- (UIColor *)detailImageColor;
- (UIColor *)overlayTextColor;
- (UIColor *)messageBackgroundColor;
- (UIColor *)usernameTextColor;
- (UIColor *)ownUsernameTextColor;
- (UIColor *)modTextColor;
- (UIColor *)placeholderTextColor;
- (UIColor *)successTextColor;
- (UIColor *)warnTextColor;
- (UIColor *)textViewBackgroundColor;
- (UIColor *)textViewTextColor;
- (UIColor *)textViewDisabledTextColor;
- (UIColor *)navigationBarBackgroundColor;
- (UIColor *)navigationBarTextColor;
- (UIColor *)toolbarBackgroundColor;
- (UIColor *)tableViewBackgroundColor;
- (UIColor *)tableViewHeaderTextColor;
- (UIColor *)tableViewFooterTextColor;
- (UIColor *)tableViewSeparatorColor;
- (UIColor *)refreshControlBackgroundColor;
- (UIColor *)searchBarBackgroundColor;
- (UIColor *)searchFieldBackgroundColor;
- (UIColor *)searchFieldTextColor;
- (UIColor *)tableViewCellBackgroundColor;
- (UIColor *)tableViewCellSelectedBackgroundColor;
- (UIColor *)badgeViewBackgroundColor;
- (UIColor *)webViewBackgroundColor;
- (UIColor *)loadingIndicatorColor;

@end

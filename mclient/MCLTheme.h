//
//  MCLTheme.h
//  mclient
//
//  Created by Christopher Reitz on 11/01/2017.
//  Copyright © 2017 Christopher Reitz. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MCLTheme <NSObject>

- (BOOL)isDark;
- (UIColor *)tintColor;
- (UIColor *)backgroundColor;
- (UIColor *)textColor;
- (UIColor *)detailTextColor;
- (UIColor *)overlayTextColor;
- (UIColor *)usernameTextColor;
- (UIColor *)ownUsernameTextColor;
- (UIColor *)modTextColor;
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

@end

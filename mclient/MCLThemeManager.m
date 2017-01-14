//
//  MCLThemeManager.m
//  mclient
//
//  Created by Christopher Reitz on 11/01/2017.
//  Copyright © 2017 Christopher Reitz. All rights reserved.
//

#import "MCLThemeManager.h"

#import <WebKit/WebKit.h>
#import "MCLTheme.h"
#import "MCLDetailView.h"
#import "MCLLoadingView.h"
#import "MCLErrorView.h"
#import "MCLReadSymbolView.h"
#import "MCLBadgeView.h"

@implementation MCLThemeManager

#pragma mark Singleton Methods

+ (id)sharedManager
{
    static MCLThemeManager *sharedThemeManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedThemeManager = [[self alloc] init];
    });

    return sharedThemeManager;
}

#pragma mark Public

- (void)applyTheme: (id <MCLTheme>)theme
{
    self.currentTheme = theme;

    UIBarStyle barStyle = [theme isDark] ? UIBarStyleBlack : UIBarStyleDefault;
    [[UINavigationBar appearance] setBarStyle:barStyle];

    [[UILabel appearance] setTextColor:[theme textColor]];

    [[UINavigationBar appearance] setBarTintColor:[theme navigationBarBackgroundColor]];
    [[UINavigationBar appearance] setTranslucent:YES];
    [[UINavigationBar appearance] setAlpha:0.7f];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [theme navigationBarTextColor]}];

    [[UIToolbar appearance] setBarTintColor:[theme toolbarBackgroundColor]];
    [[UIToolbar appearance] setTintColor:[theme tintColor]];

    [[UITableView appearance] setBackgroundColor:[theme tableViewBackgroundColor]];
    [[UITableView appearance] setSeparatorColor:[theme tableViewSeparatorColor]];

    [[UIRefreshControl appearance] setBackgroundColor:[theme refreshControlBackgroundColor]];

    [[UISearchBar appearance] setBackgroundImage:[[UIImage alloc] init]];
    [[UISearchBar appearance] setBackgroundColor:[theme searchBarBackgroundColor]];

    [[UITableViewCell appearance] setBackgroundColor:[theme tableViewCellBackgroundColor]];
    [[UILabel appearanceWhenContainedInInstancesOfClasses:@[[UITableViewCell class]]] setTextColor:[theme textColor]];

    [[MCLDetailView appearance] setBackgroundColor:[theme backgroundColor]];
    [[UILabel appearanceWhenContainedInInstancesOfClasses:@[[MCLDetailView class]]] setTextColor:[theme overlayTextColor]];

    [[MCLLoadingView appearance] setBackgroundColor:[theme backgroundColor]];
    [[UILabel appearanceWhenContainedInInstancesOfClasses:@[[MCLLoadingView class]]] setTextColor:[theme overlayTextColor]];

    [[MCLErrorView appearance] setBackgroundColor:[theme backgroundColor]];
    [[UILabel appearanceWhenContainedInInstancesOfClasses:@[[MCLErrorView class]]] setTextColor:[theme overlayTextColor]];

    [[MCLBadgeView appearance] setBackgroundColor:[theme badgeViewBackgroundColor]];

    [[MCLReadSymbolView appearance] setColor:[theme tintColor]];

    UIActivityIndicatorViewStyle indicatorViewStyle = [theme isDark]
        ? UIActivityIndicatorViewStyleWhite
        : UIActivityIndicatorViewStyleGray;
    [[UIActivityIndicatorView appearance] setActivityIndicatorViewStyle:indicatorViewStyle];

    [[UITextView appearance] setBackgroundColor:[theme textViewBackgroundColor]];

    UIKeyboardAppearance keyboardAppearance = [theme isDark] ? UIKeyboardAppearanceDark : UIKeyboardAppearanceLight;
    [[UITextField appearance] setKeyboardAppearance:keyboardAppearance];
    [[UITextField appearance] setTextColor:[theme textViewTextColor]];

    [[UIWebView appearance] setBackgroundColor:[theme webViewBackgroundColor]];
    [[WKWebView appearance] setBackgroundColor:[theme webViewBackgroundColor]];
    [[UIScrollView appearanceWhenContainedInInstancesOfClasses:@[[WKWebView class]]] setBackgroundColor:[theme webViewBackgroundColor]];

    NSArray *windows = [UIApplication sharedApplication].windows;
    for (UIWindow *window in windows) {
        for (UIView *view in window.subviews) {
            [view removeFromSuperview];
            [window addSubview:view];
        }
    }
}

@end

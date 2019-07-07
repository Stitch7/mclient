//
//  MCLDarkTheme.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLDarkTheme.h"
#import "MCLThemeManager.h"

@interface MCLDarkTheme()

@property (strong, nonatomic) UIColor *flatRedColor;
@property (strong, nonatomic) UIColor *royalBlueColor;
@property (strong, nonatomic) UIColor *silverColor;
@property (strong, nonatomic) UIColor *grayColor;
@property (strong, nonatomic) UIColor *darkGrayColor;
@property (strong, nonatomic) UIColor *totalDarkGrayColor;
@property (strong, nonatomic) UIColor *notSoTotalDarkGrayColor;
@property (strong, nonatomic) UIColor *nearlyBlackColor;

@end

@implementation MCLDarkTheme

- (instancetype)init
{
    self = [super init];
    if (!self) return nil;

    self.flatRedColor = [UIColor colorWithRed:0.95 green:0.26 blue:0.28 alpha:1.0];
    self.royalBlueColor = [UIColor colorWithRed:0.22 green:0.51 blue:0.97 alpha:1.0];
    self.silverColor = [UIColor colorWithRed:0.93 green:0.94 blue:0.95 alpha:1.0];
    self.grayColor = [UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1.0];
    self.darkGrayColor = [UIColor colorWithRed:0.56 green:0.56 blue:0.58 alpha:1.0];
    self.totalDarkGrayColor = [UIColor colorWithRed:0.11 green:0.11 blue:0.12 alpha:1.0];
    self.notSoTotalDarkGrayColor = [UIColor colorWithRed:0.07 green:0.07 blue:0.07 alpha:1.0];
    self.nearlyBlackColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.05 alpha:1.0];

    return self;
}

#pragma mark MCLTheme

- (NSUInteger)identifier
{
    return kMCLThemeDark;
}

- (BOOL)isDark
{
    return YES;
}

- (UIColor *)tintColor
{
    return self.royalBlueColor;
}

- (NSString *)cssTintColor
{
    return @"007aff";
}

- (NSString *)cssQuoteColor
{
    return @"a7a7aa";
}

- (UIColor *)backgroundColor
{
    return self.nearlyBlackColor;
}

- (UIColor *)textColor
{
    return [UIColor whiteColor];
}

- (UIColor *)detailTextColor
{
    return self.darkGrayColor;
}

- (UIColor *)detailImageColor
{
    return self.darkGrayColor;
}

- (UIColor *)overlayTextColor
{
    return self.darkGrayColor;
}

- (UIColor *)messageBackgroundColor
{
    return self.nearlyBlackColor;
}

- (UIColor *)usernameTextColor
{
    return self.silverColor;
}

- (UIColor *)ownUsernameTextColor
{
    return self.royalBlueColor;
}

- (UIColor *)modTextColor
{
    return self.flatRedColor;
}

- (UIColor *)placeholderTextColor
{
    return [UIColor colorWithRed:0.49 green:0.49 blue:0.50 alpha:1.0];
}

- (UIColor *)successTextColor
{
    return [UIColor colorWithRed:0.30 green:0.85 blue:0.39 alpha:1.0];
}

- (UIColor *)warnTextColor;
{
    return self.flatRedColor;
}

- (UIColor *)textViewBackgroundColor
{
    return self.notSoTotalDarkGrayColor;
}

- (UIColor *)textViewTextColor
{
    return [UIColor whiteColor];
}

- (UIColor *)textViewDisabledTextColor
{
    return self.nearlyBlackColor;
}

- (UIColor *)navigationBarBackgroundColor
{
    return self.nearlyBlackColor;
}

- (UIColor *)navigationBarTextColor
{
    return [UIColor whiteColor];
}

- (UIColor *)toolbarBackgroundColor
{
    return self.nearlyBlackColor;
}

- (UIColor *)tableViewBackgroundColor
{
    return self.nearlyBlackColor;
}

- (UIColor *)tableViewHeaderTextColor
{
    return [UIColor colorWithRed:0.80 green:0.80 blue:0.80 alpha:1.0];
}

- (UIColor *)tableViewFooterTextColor
{
    return [UIColor colorWithRed:0.80 green:0.80 blue:0.80 alpha:1.0];
}

- (UIColor *)tableViewSeparatorColor
{
    return self.grayColor;
}

- (UIColor *)refreshControlBackgroundColor
{
    return self.nearlyBlackColor;
}

- (UIColor *)searchBarBackgroundColor
{
    return self.nearlyBlackColor;
}

- (UIColor *)searchFieldBackgroundColor
{
    return self.totalDarkGrayColor;
}

- (UIColor *)searchFieldTextColor
{
    return [UIColor whiteColor];
}

- (UIColor *)tableViewCellBackgroundColor
{
    return self.totalDarkGrayColor;
}

- (UIColor *)tableViewCellSelectedBackgroundColor
{
    return [UIColor colorWithRed:0.23 green:0.23 blue:0.24 alpha:1.0];
}

- (UIColor *)badgeViewBackgroundColor
{
    return self.nearlyBlackColor;
}

- (UIColor *)webViewBackgroundColor
{
    return self.nearlyBlackColor;
}

- (UIColor *)loadingIndicatorColor
{
    return [UIColor whiteColor];
}

@end

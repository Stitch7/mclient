//
//  MCLLightTheme.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLLightTheme.h"
#import "MCLThemeManager.h"

@interface MCLLightTheme()

@property (strong, nonatomic) UIColor *royalBlueColor;

@end

@implementation MCLLightTheme

- (instancetype)init
{
    self = [super init];
    if (!self) return nil;

    self.royalBlueColor = [UIColor colorWithRed:0 green:0.478 blue:1 alpha:1.0];

    return self;
}

#pragma mark MCLTheme

- (NSUInteger)identifier
{
    return kMCLThemeLight;
}

- (BOOL)isDark
{
    return NO;
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
    return @"808080";
}

- (UIColor *)backgroundColor
{
    return [UIColor whiteColor];
}

- (UIColor *)textColor
{
    return [UIColor blackColor];
}

- (UIColor *)detailTextColor
{
    return [UIColor darkGrayColor];
}

- (UIColor *)detailImageColor
{
    return [UIColor blackColor];
}

- (UIColor *)overlayTextColor
{
    return [UIColor darkTextColor];
}

- (UIColor *)messageBackgroundColor
{
    return [UIColor groupTableViewBackgroundColor];
}

- (UIColor *)usernameTextColor
{
    return [UIColor blackColor];
}

- (UIColor *)ownUsernameTextColor
{
    return self.royalBlueColor;
}

- (UIColor *)modTextColor
{
    return [UIColor redColor];
}

- (UIColor *)placeholderTextColor
{
    return [UIColor colorWithRed:0.64 green:0.64 blue:0.66 alpha:1.0];
}

- (UIColor *)successTextColor
{
    return [UIColor colorWithRed:0.30 green:0.85 blue:0.39 alpha:1.0];
}

- (UIColor *)warnTextColor;
{
    return [UIColor redColor];
}

- (UIColor *)textViewBackgroundColor
{
    return [UIColor whiteColor];
}

- (UIColor *)textViewTextColor
{
    return [UIColor blackColor];
}

- (UIColor *)navigationBarBackgroundColor
{
    return nil;
}

- (UIColor *)navigationBarTextColor
{
    return [UIColor blackColor];
}

- (UIColor *)textViewDisabledTextColor
{
    return [UIColor lightGrayColor];
}

- (UIColor *)toolbarBackgroundColor
{
    return nil;
}

- (UIColor *)tableViewHeaderTextColor
{
    return [UIColor colorWithRed:0.43 green:0.43 blue:0.45 alpha:1.0];
}

- (UIColor *)tableViewFooterTextColor
{
    return [UIColor colorWithRed:0.43 green:0.43 blue:0.45 alpha:1.0];
}

- (UIColor *)tableViewBackgroundColor
{
    return [UIColor groupTableViewBackgroundColor];
}

- (UIColor *)tableViewSeparatorColor
{

    return [UIColor colorWithRed:0.78 green:0.78 blue:0.80 alpha:1.0];
}

- (UIColor *)refreshControlBackgroundColor
{
    return [UIColor groupTableViewBackgroundColor];
}

- (UIColor *)searchBarBackgroundColor
{
    return [UIColor colorWithRed:0.79 green:0.79 blue:0.81 alpha:1.0];
}

- (UIColor *)searchFieldBackgroundColor
{
    return [UIColor whiteColor];
}

- (UIColor *)searchFieldTextColor
{
    return [UIColor blackColor];
}

- (UIColor *)tableViewCellBackgroundColor
{
    return [UIColor whiteColor];
}

- (UIColor *)tableViewCellSelectedBackgroundColor
{
    return [UIColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:1.0];
}

- (UIColor *)badgeViewBackgroundColor
{
    return [UIColor groupTableViewBackgroundColor];
}

- (UIColor *)webViewBackgroundColor
{
    return [UIColor clearColor];
}

- (UIColor *)loadingIndicatorColor
{
    return [UIColor darkTextColor];
}
    
@end

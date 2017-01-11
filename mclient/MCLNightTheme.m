//
//  MCLNightTheme.m
//  mclient
//
//  Created by Christopher Reitz on 11/01/2017.
//  Copyright © 2017 Christopher Reitz. All rights reserved.
//

#import "MCLNightTheme.h"

@interface MCLNightTheme()

@property (strong, nonatomic) UIColor *royalBlueColor;
@property (strong, nonatomic) UIColor *grayColor;
@property (strong, nonatomic) UIColor *darkGrayColor;
@property (strong, nonatomic) UIColor *totalDarkGrayColor;
@property (strong, nonatomic) UIColor *notSoTotalDarkGrayColor;

@end

@implementation MCLNightTheme

- (id)init
{
    if (self = [super init]) {
        self.royalBlueColor = [UIColor colorWithRed:0 green:0.478 blue:1 alpha:1.0];
        self.grayColor = [UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1.0];
        self.darkGrayColor = [UIColor colorWithRed:0.56 green:0.56 blue:0.58 alpha:1.0];
        self.totalDarkGrayColor = [UIColor colorWithRed:0.09 green:0.09 blue:0.09 alpha:1.0];
        self.notSoTotalDarkGrayColor = [UIColor colorWithRed:0.07 green:0.07 blue:0.07 alpha:1.0];
    }

    return self;
}

#pragma mark MCLTheme

- (BOOL)isDark
{
    return YES;
}

- (UIColor *)tintColor
{
    return self.royalBlueColor;
}

- (UIColor *)backgroundColor
{
    return [UIColor blackColor];
}

- (UIColor *)textColor
{
    return [UIColor whiteColor];
}

- (UIColor *)detailTextColor
{
    return self.darkGrayColor;
}

- (UIColor *)overlayTextColor
{
    return self.darkGrayColor;
}

- (UIColor *)usernameTextColor
{
    return self.royalBlueColor;
}

- (UIColor *)modTextColor
{
    return [UIColor redColor];
}

- (UIColor *)warnTextColor;
{
    return [UIColor redColor];
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
    return [UIColor blackColor];
}

- (UIColor *)navigationBarBackgroundColor
{
    return [UIColor blackColor];
}

- (UIColor *)navigationBarTextColor
{
    return [UIColor whiteColor];
}

- (UIColor *)toolbarBackgroundColor
{
    return [UIColor blackColor];
}

- (UIColor *)tableViewBackgroundColor
{
    return [UIColor blackColor];
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
    return [UIColor blackColor];
}

- (UIColor *)searchBarBackgroundColor
{
    return [UIColor blackColor];
}

- (UIColor *)searchFieldBackgroundColor
{
    return self.grayColor;
}

- (UIColor *)searchFieldTextColor
{
    return self.darkGrayColor;
}

- (UIColor *)tableViewCellBackgroundColor
{
    return self.totalDarkGrayColor;
}

- (UIColor *)tableViewCellSelectedBackgroundColor
{
    return [UIColor blackColor];
}

- (UIColor *)badgeViewBackgroundColor
{
    return [UIColor blackColor];
}

- (UIColor *)webViewBackgroundColor
{
    return [UIColor blackColor];
}

@end

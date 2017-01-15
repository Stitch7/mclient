//
//  MCLDefaultTheme.m
//  mclient
//
//  Created by Christopher Reitz on 11/01/2017.
//  Copyright © 2017 Christopher Reitz. All rights reserved.
//

#import "MCLDefaultTheme.h"

@interface MCLDefaultTheme()

@property (strong, nonatomic) UIColor *royalBlueColor;

@end

@implementation MCLDefaultTheme

- (id)init
{
    if (self = [super init]) {
        self.royalBlueColor = [UIColor colorWithRed:0 green:0.478 blue:1 alpha:1.0];
    }

    return self;
}

#pragma mark MCLTheme

- (BOOL)isDark
{
    return NO;
}

- (UIColor *)tintColor
{
    return self.royalBlueColor;
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

- (UIColor *)overlayTextColor
{
    return [UIColor darkTextColor];
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

-(UIColor *)successTextColor
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
    return [UIColor whiteColor];
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
    return [UIColor groupTableViewBackgroundColor];
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
    return [UIColor whiteColor];
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
    return [UIColor colorWithRed:0.56 green:0.56 blue:0.58 alpha:1.0];
}

- (UIColor *)tableViewCellBackgroundColor
{
    return [UIColor whiteColor];
}

- (UIColor *)tableViewCellSelectedBackgroundColor
{
    return [UIColor groupTableViewBackgroundColor];
}

- (UIColor *)badgeViewBackgroundColor
{
    return [UIColor groupTableViewBackgroundColor];
}

- (UIColor *)webViewBackgroundColor
{
    return [UIColor clearColor];
}

@end

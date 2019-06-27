//
//  UISearchBar+getSearchField.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "UISearchBar+getSearchField.h"


@implementation UISearchBar (getSearchField)

#pragma mark - Public

- (UITextField *)getSearchField
{
    return [self findSearchFieldInView:self];
}

#pragma mark - Private Helper

- (UITextField *)findSearchFieldInView:(UIView *)view
{
    if ([view isKindOfClass:[UITextField class]]) {
        return (UITextField *)view;
    }

    UITextField *searchField;
    for (UIView *subview in view.subviews) {
        searchField = [self findSearchFieldInView:subview];
        if (searchField) {
            break;
        }
    }

    return searchField;
}

@end

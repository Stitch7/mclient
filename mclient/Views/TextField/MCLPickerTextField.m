//
//  MCLPickerTextField.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLPickerTextField.h"

@implementation MCLPickerTextField

// Hide cursor
- (CGRect)caretRectForPosition:(UITextPosition *)position
{
    return CGRectZero;
}

@end

//
//  MCLTextView.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@class MCLThemeManager;

@interface MCLTextView : UITextView

@property (strong, nonatomic) MCLThemeManager *themeManager;

- (void)configure;

@end

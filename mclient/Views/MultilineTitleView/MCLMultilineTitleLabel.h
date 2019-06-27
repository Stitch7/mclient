//
//  MCLMultilineTitleLabel.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@class MCLThemeManager;

@interface MCLMultilineTitleLabel : UILabel

- (instancetype)initWithThemeManager:(MCLThemeManager *)themeManager andTitle:(NSString *)title;

@end

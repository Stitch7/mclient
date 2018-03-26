//
//  MCLNoDataView.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

extern NSString *const MCLNoDataViewHelpTitleKey;
extern NSString *const MCLNoDataViewHelpMessageKey;

@interface MCLNoDataView : UIView

- (instancetype)initWithMessage:(NSString *)message help:(NSDictionary *)help parentViewController:(UIViewController *)parentVC;

@end

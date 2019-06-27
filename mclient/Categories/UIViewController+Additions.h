//
//  UIViewController+Additions.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@interface UIViewController (Additions)

- (void)removeOverlayViews;
- (BOOL)isModal;
- (void)presentError:(NSError *)error;
- (void)presentError:(NSError *)error withCompletion:(void (^)(void))completion;
- (void)presentErrorWithMessage:(NSString *)message;
- (void)presentErrorWithMessage:(NSString *)message withCompletion:(void (^)(void))completion;

@end

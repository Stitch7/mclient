//
//  UIViewController+Additions.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "UIViewController+Additions.h"
#import "MCLErrorView.h"
#import "MCLLoadingView.h"

@implementation UIViewController (Additions)

- (void)removeOverlayViews
{
    for (id subview in self.view.subviews) {
        if ([[subview class] isSubclassOfClass: [MCLErrorView class]] ||
            [[subview class] isSubclassOfClass: [MCLLoadingView class]]
        ) {
            [subview removeFromSuperview];
        }
    }
}

- (BOOL)isModal
{
    if ([self presentingViewController]) {
        return YES;
    }
    if ([[[self navigationController] presentingViewController] presentedViewController] == [self navigationController]) {
        return YES;
    }
    if ([[[self tabBarController] presentingViewController] isKindOfClass:[UITabBarController class]]) {
        return YES;
    }

    return NO;
}

- (void)presentError:(NSError *)error
{
    [self presentError:error withCompletion:nil];
}

- (void)presentError:(NSError *)error withCompletion:(void (^)(void))completion
{
    [self presentErrorWithMessage:[error localizedDescription] withCompletion:completion];
}

- (void)presentErrorWithMessage:(NSString *)message
{
    [self presentErrorWithMessage:message withCompletion:nil];
}

- (void)presentErrorWithMessage:(NSString *)message withCompletion:(void (^)(void))completion;
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *action) {
                                                [alert dismissViewControllerAnimated:YES completion:nil];
                                            }]];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([self respondsToSelector:@selector(bag)]) {
        id bag = [self performSelector:@selector(bag)];
        if ([bag respondsToSelector:@selector(soundEffectPlayer)]) {
            id soundeffectPlayer = [bag performSelector:@selector(soundEffectPlayer)];
            if ([soundeffectPlayer respondsToSelector:@selector(playErrorSound)]) {
                [soundeffectPlayer performSelector:@selector(playErrorSound)];
            }
        }
    }
#pragma clang diagnostic pop

    [self presentViewController:alert animated:YES completion:completion];
}

@end

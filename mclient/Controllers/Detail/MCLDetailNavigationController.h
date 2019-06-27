//
//  MCLDetailNavigationController.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

extern NSString * const MCLDisplayModeChangedNotification;

@protocol MCLDependencyBag;

@interface MCLDetailNavigationController : UINavigationController

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag rootViewController:(UIViewController *)rootViewController;

@end

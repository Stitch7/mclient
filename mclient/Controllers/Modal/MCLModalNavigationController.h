//
//  MCLModalNavigationController.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLDependencyBag;

@interface MCLModalNavigationController : UINavigationController

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag rootViewController:(UIViewController *)rootViewController;

@end

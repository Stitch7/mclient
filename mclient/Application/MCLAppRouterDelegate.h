//
//  MCLAppRouterDelegate.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLRouterDelegate.h"

@protocol MCLDependencyBag;

@interface MCLAppRouterDelegate : NSObject <MCLRouterDelegate>

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag;

@end

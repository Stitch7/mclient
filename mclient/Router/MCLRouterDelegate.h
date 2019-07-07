//
//  MCLRouterDelegate.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@class MCLRouter;

@protocol MCLRouterDelegate <NSObject>

- (UIViewController *)createMasterViewControllerForRouter:(MCLRouter *)router withCompletionHandler:(void (^)(void))completionHandler;
- (UIViewController *)createDetailViewControllerForRouter:(MCLRouter *)router;
- (UIViewController *)handleSplitViewCollapsingForRouter:(MCLRouter *)router;
- (UIViewController *)handleSplitViewSeparatingForRouter:(MCLRouter *)router;

@end

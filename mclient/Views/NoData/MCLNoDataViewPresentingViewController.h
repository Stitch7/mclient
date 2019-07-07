//
//  MCLNoDataViewPresentingViewController.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLNoDataViewPresentingViewController <NSObject>

@property (strong, nonatomic) UITableView * _Nullable tableView;

- (void)presentViewController:(UIViewController *_Nonnull)viewControllerToPresent animated: (BOOL)flag completion:(void (^ __nullable)(void))completion;

@end

//
//  MCLLoadingViewController.h
//  mclient
//
//  Copyright © 2014 - 2017 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLDependencyBag;
@protocol MCLRequest;
@protocol MCLLoadingViewControllerDelegate;

@interface MCLLoadingViewController : UIViewController

@property (strong, nonatomic) id <MCLDependencyBag> bag;
@property (strong, nonatomic) id<MCLRequest> request;
@property (strong, nonatomic) UIViewController *contentViewController;
@property (copy, nonatomic) void (^configure)(NSArray*);
@property (weak) id<MCLLoadingViewControllerDelegate> delegate;

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag request:(id<MCLRequest>)request contentViewController:(UIViewController *)contentViewController configure:(void (^)(NSArray*))configure;

- (void)load;
- (void)startLoading;
- (void)stopLoading;
- (void)showErrorView:(NSError *)error;
- (void)resetError;
- (void)refresh;
- (void)updateTitle;

@end

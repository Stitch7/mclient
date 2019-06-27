//
//  MCLLoadingViewController.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLDependencyBag;
@protocol MCLLoadingViewControllerDelegate;
@protocol MCLRequest;

typedef NS_ENUM(NSUInteger, kMCLLoadingState) {
    kMCLLoadingStateVoid,
    kMCLLoadingStateLoading,
    kMCLLoadingStateError,
    kMCLLoadingStateNoNetworkConnection,
    kMCLLoadingStateDisplayContent
};

@interface MCLLoadingViewController : UIViewController

@property (strong, nonatomic) id <MCLDependencyBag> bag;
@property (strong, nonatomic) NSDictionary *requests;
@property (weak) id<MCLLoadingViewControllerDelegate> delegate;
@property (assign, nonatomic) NSUInteger state;
@property (strong, nonatomic) UIViewController *contentViewController;

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag requests:(NSDictionary *)requests contentViewController:(UIViewController *)contentViewController withCompletionHandler:(void (^)(void))completionHandler;
- (instancetype)initWithBag:(id <MCLDependencyBag>)bag requests:(NSDictionary *)requests contentViewController:(UIViewController *)contentViewController;
- (instancetype)initWithBag:(id <MCLDependencyBag>)bag request:(id<MCLRequest>)request contentViewController:(UIViewController *)contentViewController;

- (void)updateTitle;
- (void)updateToolbar;
- (void)showErrorOfType:(NSUInteger)type error:(NSError *)error;
- (void)removeErrorViewController;
- (void)startLoading;
- (void)stopLoading;
- (void)load;
- (void)refresh;

@end

//
//  MCLLoadingViewController.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLLoadingViewController.h"

#import <AsyncBlockOperation/AsyncBlockOperation.h>
#import "Reachability.h"

#import "MCLHTTPClient.h"
#import "MCLDependencyBag.h"
#import "UIView+addConstraints.h"
#import "MCLThemeManager.h"
#import "MCLTheme.h"
#import "MCLSoundEffectPlayer.h"
#import "MCLLoadingViewControllerDelegate.h"
#import "MCLRequest.h"
#import "MCLPacmanLoadingView.h"
#import "MCLMServiceErrorView.h"
#import "MCLInternetConnectionErrorView.h"
#import "MCLErrorViewController.h"

static NSString *kQueueOperationsChanged = @"kQueueOperationsChanged";
static NSString *kQueueKeyPath = @"operations";

@interface MCLLoadingViewController ()

@property (nonatomic, copy) void (^completionHandler)(void);
@property (strong, nonatomic) NSOperationQueue *queue;
@property (strong, nonatomic) MCLPacmanLoadingView *loadingView;
@property (strong, nonatomic) MCLErrorViewController *errorViewController;

@end

@implementation MCLLoadingViewController

#pragma mark - Initializers

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag requests:(NSDictionary *)requests contentViewController:(UIViewController *)contentViewController withCompletionHandler:(void (^)(void))completionHandler
{
    self = [super init];
    if (!self) return nil;

    self.bag = bag;
    self.requests = requests;
    self.contentViewController = contentViewController;
    self.completionHandler = completionHandler;

    [self initialize];

    if ([[contentViewController class] conformsToProtocol:@protocol(MCLLoadingViewControllerDelegate)]) {
        self.delegate = (UIViewController<MCLLoadingViewControllerDelegate> *)contentViewController;
        if ([self.delegate respondsToSelector:@selector(loadingViewController)]) {
            self.delegate.loadingViewController = self;
        }
    }

    [self updateNavigationController];

    [self startLoading];
    [self load];

    return self;
}

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag requests:(NSDictionary *)requests contentViewController:(UIViewController *)contentViewController
{
    return [self initWithBag:bag requests:requests contentViewController:contentViewController withCompletionHandler:nil];
}

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag request:(id<MCLRequest>)request contentViewController:(UIViewController *)contentViewController
{
    return [self initWithBag:bag requests:@{@(0): request} contentViewController:contentViewController];
}

- (void)dealloc
{
    [self.queue removeObserver:self forKeyPath:kQueueKeyPath context:&kQueueOperationsChanged];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)initialize
{
    self.queue = [[NSOperationQueue alloc] init];
    [self.queue addObserver:self forKeyPath:kQueueKeyPath options:0 context:&kQueueOperationsChanged];

    self.state = kMCLLoadingStateVoid;
}

#pragma mark - Queue observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.queue && [keyPath isEqualToString:kQueueKeyPath] && context == &kQueueOperationsChanged) {
        if ([self.queue.operations count] > 0) {
            return;
        }

        [self endRefreshing];
        [self callCompletionHandlerOnce];
    } else {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}

#pragma mark - Completion Handler

- (void)callCompletionHandlerOnce
{
    if (self.completionHandler) {
        self.completionHandler();
        self.completionHandler = nil;
    }
}

#pragma mark - UIViewController life cycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self toggleToolbarVisibility:YES];
}

#pragma mark - UI Setup

- (void)toggleToolbarVisibility:(BOOL)viewControllerIsOnScreen
{
//    if (self.state == kMCLLoadingStateDisplayContent) {
//        [self updateToolbar];
//    }
    BOOL toolbarIsHidden = !self.toolbarItems || !viewControllerIsOnScreen;
    [self.navigationController setToolbarHidden:toolbarIsHidden animated:NO];
}

- (void)updateNavigationItem
{
    if (!self.delegate) {
        return;
    }

    if ([self.delegate respondsToSelector:@selector(loadingViewController:configureNavigationItem:)]) {
        [self.delegate loadingViewController:nil configureNavigationItem:self.navigationItem];
    }
}

- (void)updateToolbar
{
    if (!self.delegate) {
        return;
    }

    if ([self.delegate respondsToSelector:@selector(loadingViewControllerRequestsToolbarItems:)]) {
        self.toolbarItems = [self.delegate loadingViewControllerRequestsToolbarItems:self];
        BOOL viewControllerIsOnScreen = self.viewIfLoaded.window != nil;
        [self toggleToolbarVisibility:viewControllerIsOnScreen];
    } else {
        [self.navigationController setToolbarHidden:YES animated:NO];
        self.navigationController.toolbar.hidden = YES;
    }
}

- (void)updateTitle
{
    if (!self.delegate) {
        return;
    }

    if ([self.delegate respondsToSelector:@selector(loadingViewControllerRequestsTitleString:)]) {
        self.title = [self.delegate loadingViewControllerRequestsTitleString:nil];
    }

    if ([self.delegate respondsToSelector:@selector(loadingViewControllerRequestsTitleView:)]) {
        self.navigationItem.titleView = [self.delegate loadingViewControllerRequestsTitleView:self];
    }
}

- (void)updateRefreshControl
{
    if (![self.delegate respondsToSelector:@selector(refreshControl)]) {
        return;
    }

    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];

    if (!self.delegate.refreshControl) {
        self.delegate.refreshControl = refreshControl;
        [self.delegate.refreshControl addTarget:self
                                         action:@selector(refresh)
                               forControlEvents:UIControlEventValueChanged];
    }

    if (!([self.delegate respondsToSelector:@selector(tableView)] &&
          [self.delegate respondsToSelector:@selector(refreshControlBackgroundView)]
    )) {
        return;
    }

    CGRect refreshControlBackgroundViewFrame = self.delegate.tableView.bounds;
    refreshControlBackgroundViewFrame.origin.y = -refreshControlBackgroundViewFrame.size.height;
    self.delegate.refreshControlBackgroundView = [[UIView alloc] initWithFrame:refreshControlBackgroundViewFrame];

    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.delegate.tableView;
    tableViewController.refreshControl = refreshControl;
    [tableViewController.tableView addSubview:self.delegate.refreshControlBackgroundView];
    refreshControl.layer.zPosition = self.delegate.refreshControlBackgroundView.layer.zPosition + 1;

    [self.delegate.tableView addSubview:refreshControl];
}

- (void)updateNavigationController
{
    [self updateTitle];
    [self updateNavigationItem];
    [self updateToolbar];
}

#pragma mark - Content View Controller

- (void)addContentViewContoller:(UIViewController *)contentViewController
{
    contentViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

    [self addChildViewController:contentViewController];
    [self.view insertSubview:contentViewController.view atIndex:0];
    [self.navigationController.view setNeedsLayout];

    [contentViewController.view constrainEdgesTo:self.view];
    [contentViewController didMoveToParentViewController:self];

    [self updateNavigationController];
    [self updateRefreshControl];
}

#pragma mark - Error View Controller

- (void)addErrorViewControllerWithType:(NSUInteger)type error:(NSError *)error
{
    self.errorViewController = [[MCLErrorViewController alloc] initWithBag:self.bag type:type error:error];

    [self updateNavigationController];

    [self.errorViewController.errorView.button addTarget:self
                                                  action:@selector(errorViewButtonPressed:)
                                        forControlEvents:UIControlEventTouchUpInside];
    self.errorViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

    [self addChildViewController:self.errorViewController];
    [self.view insertSubview:self.errorViewController.view atIndex:0];
    [self.view bringSubviewToFront:self.errorViewController.view];
    [self.navigationController.view setNeedsLayout];

    [self.errorViewController.view constrainEdgesTo:self.view];
    [self.errorViewController didMoveToParentViewController:self];
}

- (void)showErrorOfType:(NSUInteger)type error:(NSError *)error
{
    if (self.state == kMCLLoadingStateError) {
        return;
    }

    self.state = kMCLLoadingStateError;
    [self stopLoading];

    [self addErrorViewControllerWithType:type error:error];
}

- (void)removeErrorViewController
{
    [self.errorViewController.view removeFromSuperview];
    [self.errorViewController removeFromParentViewController];
}

- (void)errorViewButtonPressed:(UIButton *)sender
{
    [self startLoading];
    [self load];
}

- (BOOL)noInternetConnectionAvailable
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];

    return networkStatus == NotReachable;
}

#pragma mark - Data loading

- (void)load
{
    if ([self noInternetConnectionAvailable]) {
        [self callCompletionHandlerOnce];
        [self showErrorOfType:kMCLErrorTypeNoInternetConnection error:nil];
        return;
    }

    for (NSNumber *key in self.requests) {
        id<MCLRequest> request = [self.requests objectForKey:key];
        AsyncBlockOperation *operation = [AsyncBlockOperation blockOperationWithBlock:^(AsyncBlockOperation *op) {
            [request loadWithCompletionHandler:^(NSError *error, NSArray *data) {
                [self stopLoading];

                if ((error && error.code != MCLHTTPErrorCodeInvalidLogin) || !data) {
                    [self callCompletionHandlerOnce];
                    [self showErrorOfType:kMCLErrorTypeGeneral error:error];
                    [op complete];
                    return;
                }

                if (self.state != kMCLLoadingStateDisplayContent) {
                    [self addContentViewContoller:self.contentViewController];
                    self.state = kMCLLoadingStateDisplayContent;
                }

                if ([self.delegate respondsToSelector:@selector(loadingViewController:hasRefreshedWithData:forKey:)]) {
                    [self.delegate loadingViewController:nil hasRefreshedWithData:data forKey:key];
                }

                [op complete];
            }];
        }];
        [self.queue addOperation:operation];
    }
}

- (void)refresh
{
    if ([self.delegate respondsToSelector:@selector(refreshControl)]) {
        [self.delegate.refreshControl beginRefreshing];
    }
    [self load];
}

- (void)endRefreshing
{
    if (![self.delegate respondsToSelector:@selector(refreshControl)]) {
        return;
    }

    if ([self.delegate.refreshControl isRefreshing]) {
        if (self.state != kMCLLoadingStateError) {
            [self.bag.soundEffectPlayer playReloadSound];
        }
        [self.delegate.refreshControl endRefreshing];
    }
}

- (void)startLoading
{
    if (self.state == kMCLLoadingStateError) {
        [self removeErrorViewController];
    }

    self.state = kMCLLoadingStateLoading;
    self.loadingView = [[MCLPacmanLoadingView alloc] initWithTheme:self.bag.themeManager.currentTheme];
    self.loadingView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view insertSubview:self.loadingView atIndex:0];
    [self.loadingView constrainEdgesTo:self.view];
    [self.view bringSubviewToFront:self.loadingView];
}

- (void)stopLoading
{
    [self.loadingView removeFromSuperview];
}

@end

//
//  MCLSectionLoadingViewController.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//
#pragma mark - TODO: A lot of code duplications. Refactor to subclass MCLLoadingViewController

#import "MCLSectionLoadingViewController.h"

#import <AsyncBlockOperation/AsyncBlockOperation.h>
#import "Reachability.h"

#import "MCLDependencyBag.h"
#import "UIView+addConstraints.h"
#import "MCLThemeManager.h"
#import "MCLTheme.h"
#import "MCLSectionLoadingViewControllerDelegate.h"
#import "MCLRequest.h"
#import "MCLPacmanLoadingView.h"
#import "MCLMServiceErrorView.h"
#import "MCLInternetConnectionErrorView.h"
#import "MCLErrorViewController.h"


static NSString *kQueueOperationsChanged = @"kQueueOperationsChanged";

@interface MCLSectionLoadingViewController ()

@property (strong, nonatomic) NSDictionary *requests;
@property (strong, nonatomic) NSOperationQueue *queue;
@property (assign, nonatomic, getter=isLoading) BOOL loading;
@property (assign, nonatomic, getter=hasError) BOOL error;
@property (assign, nonatomic, getter=hasNoNetworkConnection) BOOL noNetworkConnection;
@property (strong, nonatomic) MCLPacmanLoadingView *loadingView;
@property (strong, nonatomic) MCLInternetConnectionErrorView *networkConnectionErrorView;
@property (strong, nonatomic) MCLMServiceErrorView *errorView;
@property (strong, nonatomic) MCLErrorViewController *errorViewController;

@end

@implementation MCLSectionLoadingViewController

#pragma mark - Initializers

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag requests:(NSDictionary *)requests forViewController:(UIViewController *)contentViewController
{
    self = [super init];
    if (!self) return nil;

    self.bag = bag;
    self.requests = requests;
    [self configure];

    self.contentViewController = contentViewController;
    if ([[contentViewController class] conformsToProtocol:@protocol(MCLSectionLoadingViewControllerDelegate)]) {
        self.delegate = (UIViewController <MCLSectionLoadingViewControllerDelegate> *) contentViewController;
        if ([self.delegate respondsToSelector:@selector(loadingViewController)]) {
            self.delegate.loadingViewController = self;
        }
    }

    [self addContentViewContoller:contentViewController];
    [self load];

    return self;
}

- (void)dealloc
{
    [self.queue removeObserver:self forKeyPath:@"operations" context:&kQueueOperationsChanged];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)configure
{
    self.queue = [[NSOperationQueue alloc] init];
    [self.queue addObserver:self forKeyPath:@"operations" options:0 context:&kQueueOperationsChanged];

    self.loading = NO;
    self.noNetworkConnection = NO;

    [self configureNotifications];
    [self configureLoadingView];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.queue && [keyPath isEqualToString:@"operations"] && context == &kQueueOperationsChanged) {
        if ([self.queue.operations count] == 0) {
            [self endRefreshing];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}

- (void)configureNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(themeChanged:)
                                                 name:MCLThemeChangedNotification
                                               object:nil];
}

- (void)configureErrorView
{
    self.errorView = [[MCLMServiceErrorView alloc] init];
    self.errorView.translatesAutoresizingMaskIntoConstraints = NO;
//    [self.errorView constrainEdgesTo:self.view];
}

- (void)configureNetworkConnectionErrorView
{
    self.networkConnectionErrorView = [[MCLInternetConnectionErrorView alloc] init];
    self.networkConnectionErrorView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.networkConnectionErrorView.button addTarget:self
                                               action:@selector(load)
                                     forControlEvents:UIControlEventTouchUpInside];
//    [self.networkConnectionErrorView constrainEdgesTo:self.view];
}

- (void)configureLoadingView
{
    self.loadingView = [[MCLPacmanLoadingView alloc] initWithTheme:self.bag.themeManager.currentTheme];
    self.loadingView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.loadingView constrainEdgesTo:self.view];
}

#pragma mark - UIViewController life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self startLoading];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self toggleToolbarVisibility];
}

#pragma mark - Private

- (void)toggleToolbarVisibility
{
    BOOL toolbarIsHidden = !self.toolbarItems;
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
        self.toolbarItems = [self.delegate loadingViewControllerRequestsToolbarItems:nil];
        [self toggleToolbarVisibility];
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

    if ([self.delegate respondsToSelector:@selector(loadingViewControllerRequestsTitleLabel:)]) {
        self.navigationItem.titleView = [self.delegate loadingViewControllerRequestsTitleLabel:nil];
    }
}

- (void)updateRefreshControl
{
    if (![self.delegate respondsToSelector:@selector(refreshControl)]) {
        return;
    }

    if (!self.delegate.refreshControl) {
        self.delegate.refreshControl = [[UIRefreshControl alloc] init];
        [self.delegate.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    }

    self.delegate.refreshControl.backgroundColor = [self.bag.themeManager.currentTheme tableViewBackgroundColor];
}

- (void)updateNavigationController
{
    [self updateTitle];
    [self updateNavigationItem];
    [self updateToolbar];
}

- (void)addContentViewContoller:(UIViewController *)contentViewController
{
    [self updateNavigationController];
    [self updateRefreshControl];

    contentViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

    [self addChildViewController:contentViewController];
    [self.view insertSubview:contentViewController.view atIndex:0];
    [self.navigationController.view setNeedsLayout];

    [contentViewController.view constrainEdgesTo:self.view];
    [contentViewController didMoveToParentViewController:self];
}

- (void)addErrorViewContoller:(NSError *)error
{
    self.errorViewController = [[MCLErrorViewController alloc] initWithBag:self.bag error:error];

    [self updateNavigationController];

    self.errorViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

    [self addChildViewController:self.errorViewController];
    [self.view insertSubview:self.errorViewController.view atIndex:0];
    [self.view bringSubviewToFront:self.errorViewController.view];
    [self.navigationController.view setNeedsLayout];

    [self.errorViewController.view constrainEdgesTo:self.view];
    [self.errorViewController didMoveToParentViewController:self];
}

- (void)load
{
    if ([self noNetworkConnectionAvailable]) {
        [self showNetworkConnectionAvailableView];
        return;
    }

    [self removeNetworkConnectionAvailableView];
    for (NSNumber *key in self.requests) {
        id<MCLRequest> request = [self.requests objectForKey:key];
        AsyncBlockOperation *operation = [AsyncBlockOperation blockOperationWithBlock:^(AsyncBlockOperation *op) {
            [request loadWithCompletionHandler:^(NSError *error, NSArray *data) {
                [self stopLoading];

                if (error || !data) {
                    [self showErrorView:error];
                    return;
                }

                if ([self.delegate respondsToSelector:@selector(loadingViewController:hasRefreshedWithData:forKey:)]) {
                    [self.delegate loadingViewController:nil hasRefreshedWithData:data forKey:key];
                }

                [self updateNavigationController];

                [op complete];
            }];
        }];
        [self.queue addOperation:operation];
    }
}

- (void)refresh
{
    [self load];
}

- (void)endRefreshing
{
    if (![self.delegate respondsToSelector:@selector(refreshControl)]) {
        return;
    }

    if ([self.delegate.refreshControl isRefreshing]) {
        [self.delegate.refreshControl endRefreshing];
    }
}

- (void)startLoading
{
    self.loading = YES;
    [self.view addSubview:self.loadingView];
}

- (void)stopLoading
{
    self.loading = NO;
    [self.loadingView removeFromSuperview];
}

- (void)showErrorView:(NSError *)error
{
    if (self.hasError || error.code == 401) {
        return;
    }

    self.error = YES;
    [self stopLoading];

    [self addErrorViewContoller:error];
}

- (void)removeErrorView
{
    if (!self.hasError) {
        return;
    }

    self.error = NO;
    [self.errorView removeFromSuperview];
}

- (BOOL)noNetworkConnectionAvailable
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];

    return networkStatus == NotReachable;
}

- (void)showNetworkConnectionAvailableView
{
    if (self.hasNoNetworkConnection) {
        return;
    }

    self.noNetworkConnection = YES;
    [self stopLoading];
    [self configureNetworkConnectionErrorView];
    [self.view addSubview:self.networkConnectionErrorView];
    [self.networkConnectionErrorView constrainEdgesTo:self.view];
}

- (void)removeNetworkConnectionAvailableView
{
    if (!self.hasNoNetworkConnection) {
        return;
    }

    self.noNetworkConnection = NO;
    [self.networkConnectionErrorView removeFromSuperview];
}

#pragma mark - Notifications

- (void)themeChanged:(NSNotification *)notification
{
    [self updateRefreshControl];
}

@end

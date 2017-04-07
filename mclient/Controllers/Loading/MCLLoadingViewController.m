//
//  MCLLoadingViewController.m
//  mclient
//
//  Copyright © 2014 - 2017 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLLoadingViewController.h"

#import "MCLDependencyBag.h"
#import "UIView+addConstraints.h"
#import "MCLLoadingViewControllerDelegate.h"
#import "MCLThemeManager.h"
#import "MCLRequest.h"
#import "MCLErrorView.h"
#import "MCLPacmanLoadingView.h"
#import "MCLMServiceErrorView.h"
#import "MCLInternetConnectionErrorView.h"
#import "MCLErrorViewController.h"

@interface MCLLoadingViewController ()

@property (assign, nonatomic, getter=isLoading) BOOL loading;
@property (assign, nonatomic, getter=hasError) BOOL error;
@property (assign, nonatomic, getter=hasNoNetworkConnection) BOOL noNetworkConnection;
@property (strong, nonatomic) MCLPacmanLoadingView *loadingView;
@property (strong, nonatomic) MCLInternetConnectionErrorView *networkConnectionErrorView;
@property (strong, nonatomic) MCLMServiceErrorView *errorView;
@property (strong, nonatomic) MCLErrorViewController *errorViewController;

@end

@implementation MCLLoadingViewController

# pragma mark: - Initializers

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag request:(id<MCLRequest>)request contentViewController:(UIViewController *)contentViewController configure:(void (^)(NSArray*))configure
{
    self = [super init];
    if (!self) return nil;

    self.bag = bag;
    self.request = request;
    self.contentViewController = contentViewController;
    self.configure = configure;

    [self initialize];

    if ([[contentViewController class] conformsToProtocol:@protocol(MCLLoadingViewControllerDelegate)]) {
        self.delegate = (UIViewController <MCLLoadingViewControllerDelegate> *)contentViewController;
        if ([self.delegate respondsToSelector:@selector(loadingViewController)]) {
            self.delegate.loadingViewController = self;
        }
    }

    [self updateNavigationController];

    [self startLoading];
    [self load];

    return self;
}

- (void)initialize
{
    self.loading = NO;
    self.noNetworkConnection = NO;
}

- (void)configureErrorView
{
    self.errorView = [[MCLMServiceErrorView alloc] init];
    self.errorView.translatesAutoresizingMaskIntoConstraints = NO;
//    [self.errorView constrainEdgesTo:self.view];
}

# pragma mark: - UIViewController life cycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self toggleToolbarVisibility];
}

# pragma mark: - Private

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
        [self.delegate loadingViewController:self configureNavigationItem:self.navigationItem];
    }
}

- (void)updateToolbar
{
    if (!self.delegate) {
        return;
    }

    if ([self.delegate respondsToSelector:@selector(loadingViewControllerRequestsToolbarItems:)]) {
        self.toolbarItems = [self.delegate loadingViewControllerRequestsToolbarItems:self];
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
        NSString *title = [self.delegate loadingViewControllerRequestsTitleString:self];
        self.navigationItem.title = title;
        self.title = title;
    }

    if ([self.delegate respondsToSelector:@selector(loadingViewControllerRequestsTitleLabel:)]) {
        self.navigationItem.titleView = [self.delegate loadingViewControllerRequestsTitleLabel:self];
    }
}

- (void)updateRefreshControl
{
    if (![self.delegate respondsToSelector:@selector(refreshControl)]) {
        return;
    }

    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    self.delegate.refreshControl = refreshControl;

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

- (void)addContentViewContoller:(UIViewController *)contentViewController
{
    self.contentViewController = contentViewController;

    contentViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

    [self addChildViewController:contentViewController];

    [self.view insertSubview:contentViewController.view atIndex:0];
    [self.navigationController.view setNeedsLayout];

    [contentViewController.view constrainEdgesTo:self.view];
    [contentViewController didMoveToParentViewController:self];

    [self updateNavigationController];
    [self updateRefreshControl];
}

- (void)addErrorViewContoller:(NSError *)error
{
    self.errorViewController = [[MCLErrorViewController alloc] initWithError:error];

    [self updateNavigationController];

    self.errorViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

    [self addChildViewController:self.errorViewController];
    [self.view insertSubview:self.errorViewController.view atIndex:0];
    [self.view bringSubviewToFront:self.errorViewController.view];
    [self.navigationController.view setNeedsLayout];

    [self.errorViewController.view constrainEdgesTo:self.view];
    [self.errorViewController didMoveToParentViewController:self];
}

#pragma mark - Public

- (void)load
{
    [self.request loadWithCompletionHandler:^(NSError *error, NSArray *data) {
        [self stopLoading];

        if ((error && error.code != 401) || !data) {
            [self showErrorView:error];
            return;
        }

        self.configure(data);
        [self addContentViewContoller:self.contentViewController];
    }];
}

- (void)startLoading
{
    self.loading = YES;
    self.loadingView = [[MCLPacmanLoadingView alloc] initWithTheme:self.bag.themeManager.currentTheme];
    self.loadingView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view insertSubview:self.loadingView atIndex:0];
    [self.loadingView constrainEdgesTo:self.view];
    [self.view bringSubviewToFront:self.loadingView];
}

- (void)stopLoading
{
    self.loading = NO;
    [self.loadingView removeFromSuperview];
}

- (void)showErrorView:(NSError *)error
{
//    [self.view addSubview:self.errorView];
    if (self.hasError) {
        return;
    }

    self.error = YES;
    [self stopLoading];

    [self addErrorViewContoller:error];
}

- (void)resetError
{
    [self.errorView removeFromSuperview];
}

- (void)refresh
{
    if ([self.delegate respondsToSelector:@selector(refreshControl)] && !self.delegate.refreshControl.isRefreshing) {
        [self.delegate.refreshControl beginRefreshing];
    }

    [self.request loadWithCompletionHandler:^(NSError *error, NSArray *data) {
        if (error || !data) {
            [self showErrorView:error];
            return;
        }

        if ([self.delegate respondsToSelector:@selector(loadingViewController:hasRefreshedWithData:)]) {
            [self.delegate loadingViewController:self hasRefreshedWithData:data];
        }

        if ([self.delegate respondsToSelector:@selector(refreshControl)] && self.delegate.refreshControl.isRefreshing) {
            [self.delegate.refreshControl endRefreshing];
        }
    }];
}

@end

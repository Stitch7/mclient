//
//  MCLSectionLoadingViewControllerDelegate.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@class MCLSectionLoadingViewController;

@protocol MCLSectionLoadingViewControllerDelegate <NSObject>

@optional

@property (weak, nonatomic) MCLSectionLoadingViewController *loadingViewController;
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) UIView *refreshControlBackgroundView;

- (NSString *)loadingViewControllerRequestsTitleString:(MCLSectionLoadingViewController *)loadingViewController;
- (UILabel *)loadingViewControllerRequestsTitleLabel:(MCLSectionLoadingViewController *)loadingViewController;
- (NSArray<__kindof UIBarButtonItem *> *)loadingViewControllerRequestsToolbarItems:(MCLSectionLoadingViewController *)loadingViewController;
- (void)loadingViewController:(MCLSectionLoadingViewController *)loadingViewController configureNavigationItem:(UINavigationItem *)navigationItem;
- (void)loadingViewControllerStartsRefreshing:(MCLSectionLoadingViewController *)loadingViewController;
- (void)loadingViewController:(MCLSectionLoadingViewController *)loadingViewController hasRefreshedWithData:(NSArray *)newData forKey:(NSNumber *)key;

@end

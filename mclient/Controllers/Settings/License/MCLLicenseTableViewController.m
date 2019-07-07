//
//  MCLLicenseTableViewController.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLLicenseTableViewController.h"

#import "UIView+addConstraints.h"
#import "MCLDependencyBag.h"
#import "MCLThemeManager.h"
#import "MCLTheme.h"
#import "MCLLicense.h"
#import "MCLLicenseContainer.h"
#import "MCLLicenseViewController.h"


NSString *const MCLLicenseTableViewCellIdentifier = @"LicenseCell";

@interface MCLLicenseTableViewController ()

@property (strong, nonatomic) id <MCLDependencyBag> bag;
@property (strong, nonatomic) MCLLicenseContainer *licenseContainer;

@end

@implementation MCLLicenseTableViewController

#pragma mark - Initializers

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (!self) return nil;

    self.bag = bag;
    self.licenseContainer = [[MCLLicenseContainer alloc] init];

    return self;
}

#pragma mark - ViewController life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Licenses", nil);
    [self configureTableView];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    // Update the header frame on device rotation
    // Must be wrapped in dispatch_async to be considered in next draw loop
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView.tableHeaderView layoutIfNeeded];
        self.tableView.tableHeaderView = self.tableView.tableHeaderView;
    });
}

#pragma mark - Configuration

- (void)configureTableView
{
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:MCLLicenseTableViewCellIdentifier];

    UILabel *headerLabel = [[UILabel alloc] init];
    headerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    headerLabel.numberOfLines = 0;
    headerLabel.lineBreakMode = NSLineBreakByWordWrapping;
    headerLabel.font = [UIFont systemFontOfSize:16.0];
    headerLabel.textColor = [self.bag.themeManager.currentTheme tableViewHeaderTextColor];
    headerLabel.text = NSLocalizedString(@"m!client is using the following open-source libraries", nil);

    UIView *headerView = [[UIView alloc] init];
    headerView.translatesAutoresizingMaskIntoConstraints = NO;
    [headerView addSubview:headerLabel];
    [headerLabel constrainEdgesToMarginOf:headerView];
    self.tableView.tableHeaderView = headerView;

    [headerView.centerXAnchor constraintEqualToAnchor:self.tableView.centerXAnchor].active = YES;
    [headerView.widthAnchor constraintEqualToAnchor:self.tableView.widthAnchor].active = YES;
    [headerView.topAnchor constraintEqualToAnchor:self.tableView.topAnchor].active = YES;

    [self.tableView.tableHeaderView layoutIfNeeded];
    self.tableView.tableHeaderView = headerView;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.licenseContainer count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MCLLicenseTableViewCellIdentifier
                                                            forIndexPath:indexPath];

    cell.backgroundColor = [self.bag.themeManager.currentTheme tableViewCellBackgroundColor];
    UIView *backgroundView = [[UIView alloc] initWithFrame:cell.frame];
    backgroundView.backgroundColor = [self.bag.themeManager.currentTheme tableViewCellSelectedBackgroundColor];
    cell.selectedBackgroundView = backgroundView;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.textColor = [self.bag.themeManager.currentTheme textColor];

    MCLLicense *license = [self.licenseContainer licenseAtIndex:indexPath.row];
    cell.textLabel.text = license.name;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MCLLicense *license = [self.licenseContainer licenseAtIndex:indexPath.row];
    MCLLicenseViewController *licenseVC = [[MCLLicenseViewController alloc] initWithBag:self.bag andLicense:license];
    [self.navigationController pushViewController:licenseVC animated:YES];
}

@end

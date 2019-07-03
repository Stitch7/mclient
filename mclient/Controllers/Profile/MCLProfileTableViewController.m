//
//  MCLProfileTableViewController.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLProfileTableViewController.h"

#import "MCLDependencyBag.h"
#import "MCLTheme.h"
#import "MCLThemeManager.h"
#import "MCLRouter+privateMessages.h"
#import "MCLUser.h"
#import "MCLPrivateMessageConversation.h"
#import "MCLLoadingViewController.h"


static NSString *MCLProfileCellIdentifier = @"ProfileCell";

@interface MCLProfileTableViewController ()

@property (strong, nonatomic) NSMutableArray *profileKeys;
@property (strong, nonatomic) NSMutableDictionary *profileData;

@end

@implementation MCLProfileTableViewController

#pragma mark - Initializers

- (instancetype)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (!self) return nil;

    [self configureNotifications];
    [self configureTableView];

    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Configuration

- (void)configureNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(themeChanged:)
                                                 name:MCLThemeChangedNotification
                                               object:nil];
}

- (void)configureTableView
{
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:MCLProfileCellIdentifier];
}

- (void)configureHeaderView
{
    UIView *headerView = [[UIView alloc] init];

    UIImageView *profileImageView = [[UserAvatarImageView alloc] initWithFrame:CGRectMake(0, 0, 120, 120) user:self.user];
    profileImageView.contentMode = UIViewContentModeTopLeft;
    [headerView addSubview:profileImageView];
    self.tableView.tableHeaderView = headerView;

    CGFloat padding = 20;

    CGFloat height = [profileImageView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + padding;

    // Update the header's frame and set it again
    CGRect headerFrame = profileImageView.frame;
    headerFrame.size = CGSizeMake(profileImageView.bounds.size.width, height);
    headerView.frame = headerFrame;

    CGRect profileImageFrame = profileImageView.frame;
    profileImageFrame.origin = CGPointMake(padding, padding);
    profileImageView.frame = profileImageFrame;
    self.tableView.tableHeaderView = headerView;
}

#pragma mark - MCLLoadingContentViewControllerDelegate

- (NSString *)loadingViewControllerRequestsTitleString:(MCLLoadingViewController *)loadingViewController
{
    [self.tableView reloadData];
    return self.user.username;
}

- (void)loadingViewController:(MCLLoadingViewController *)loadingViewController configureNavigationItem:(UINavigationItem *)navigationItem
{
    navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"downButton"]
                                                                        style:UIBarButtonItemStylePlain
                                                                       target:self
                                                                       action:@selector(doneButtonPressed:)];

    if (self.loadingViewController.state == kMCLLoadingStateLoading) {
//        if ([self.user.username isEqualToString:self.bag.loginManager.username]) {
//            navigationItem.rightBarButtonItem = self.editButtonItem;
//        } else
        if (self.showPrivateMessagesButton) {
            navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"privateMessages"]
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:self
                                                                                action:@selector(privateMessagesButtonPressed:)];
        } else {
            navigationItem.rightBarButtonItem = nil;
        }
    }
}

- (void)loadingViewController:(MCLLoadingViewController *)loadingViewController hasRefreshedWithData:(NSArray *)newData forKey:(NSNumber *)key
{
    self.profileKeys = [newData.firstObject mutableCopy];
    self.profileData = [newData.lastObject mutableCopy];
    [self.profileData removeObjectForKey:@"picture"];
    __block NSUInteger profileKeyIndex;
    [self.profileKeys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger i, BOOL *stop) {
        if ([key isEqualToString:@"picture"]) {
            profileKeyIndex = i;
            *stop = YES;
        }
    }];
    [self.profileKeys removeObjectAtIndex:profileKeyIndex];
    [self configureHeaderView];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.profileKeys count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MCLProfileCellIdentifier forIndexPath:indexPath];
    NSString *text = [self.profileData objectForKey:self.profileKeys[indexPath.section]];
    cell.textLabel.text = text.length ? text : @"-";
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.textColor = [self.bag.themeManager.currentTheme textColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedString(self.profileKeys[section], nil);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

#pragma mark - Actions

- (void)doneButtonPressed:(UIBarButtonItem *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)privateMessagesButtonPressed:(UIBarButtonItem *)sender
{
    MCLPrivateMessageConversation *conversation = [self.bag.privateMessagesManager conversationForUser:self.user];
    [self.bag.router pushToPrivateMessagesConversation:conversation];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Notifications

- (void)themeChanged:(NSNotification *)notification
{
    [self.tableView setSeparatorColor:[self.bag.themeManager.currentTheme tableViewSeparatorColor]];
    [self.tableView reloadData];
}

@end

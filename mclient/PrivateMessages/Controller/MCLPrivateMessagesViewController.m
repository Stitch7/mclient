//
//  MCLPrivateMessagesViewController.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLPrivateMessagesViewController.h"

#import "MCLDependencyBag.h"
#import "MCLRouter+privateMessages.h"
#import "MCLTheme.h"
#import "MCLThemeManager.h"
#import "MCLLoadingViewController.h"
#import "MCLUserSearchViewController.h"
#import "MCLPrivateMessagesManager.h"
#import "MCLPrivateMessageConversation.h"
#import "MCLUserSearchDelegate.h"


@interface MCLPrivateMessagesViewController () <MCLUserSearchDelegate>

@property (strong, nonatomic) id <MCLDependencyBag> bag;
//@property (strong, nonatomic) NSArray *conversations;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation MCLPrivateMessagesViewController

#pragma mark - Lazy Properties

- (NSDateFormatter *)dateFormatter
{
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.doesRelativeDateFormatting = YES;
        _dateFormatter.dateStyle = NSDateFormatterShortStyle;
        _dateFormatter.timeStyle = NSDateFormatterShortStyle;
    }

    return _dateFormatter;
}

#pragma mark - Initializers

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (!self) return nil;

    self.bag = bag;
    [self configureNotifications];

    return self;
}

- (void)configureNotifications
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(privateMessagesChanged:)
                               name:MCLPrivateMessagesChangedNotification
                             object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - ViewController life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self configureNavigationBar];
    [self configureTableView];
}

#pragma mark - Configuration

- (void)configureNavigationBar
{
    self.title = NSLocalizedString(@"Private Messages", nil);

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                                                                                           target:self
                                                                                           action:@selector(composeButtonPressed:)];

    [self.navigationController setToolbarHidden:YES animated:NO];

}

- (void)configureTableView
{
    UINib *messageCellNib = [UINib nibWithNibName: @"PrivateMessagesConversationTableViewCell" bundle: nil];
    [self.tableView registerNib:messageCellNib forCellReuseIdentifier:PrivateMessagesConversationTableViewCell.Identifier];

    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = UITableViewAutomaticDimension;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.bag.privateMessagesManager.conversations count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PrivateMessagesConversationTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:PrivateMessagesConversationTableViewCell.Identifier];
    cell.bag = self.bag;
    cell.dateFormatter = self.dateFormatter;
    MCLPrivateMessageConversation *conversation = (MCLPrivateMessageConversation *)self.bag.privateMessagesManager.conversations[indexPath.row];
    cell.conversation = conversation;

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MCLPrivateMessageConversation *selectedConversation = (MCLPrivateMessageConversation *)self.bag.privateMessagesManager.conversations[indexPath.row];
    [self.bag.router pushToPrivateMessagesConversation:selectedConversation];
}

#pragma mark - Actions

- (void)composeButtonPressed:(UIBarButtonItem *)sender
{
    MCLUserSearchViewController *userSearchVC = [self.bag.router pushToUserSearch];
    userSearchVC.title = @"Select receiver"; // TODO i18n
    userSearchVC.delegate = self;
}

#pragma mark - Notifications

- (void)privateMessagesChanged:(NSNotification *)notification
{
    [self.tableView reloadData];
}

#pragma mark - MCLUserSearchDelegate

- (void)userSearchViewController:(MCLUserSearchViewController *)userSearchViewController didPickUser:(MCLUser *)user
{
    MCLPrivateMessageConversation *conversation = [self.bag.privateMessagesManager conversationForUser:user];
    [self.bag.router pushToPrivateMessagesConversation:conversation];
}

@end

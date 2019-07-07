//
//  MCLDraftTableViewController.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLDraftTableViewController.h"

#import "MCLDependencyBag.h"
#import "MCLRouter+composeMessage.h"
#import "MCLThemeManager.h"
#import "MCLMessage.h"
#import "MCLDraft.h"
#import "MCLDraftManager.h"
#import "MCLDraftTableViewCell.h"
#import "MCLComposeMessageViewController.h"
#import "MCLComposeMessageViewControllerDelegate.h"


@interface MCLDraftTableViewController () <MCLComposeMessageViewControllerDelegate>

@property (strong, nonatomic) id <MCLDependencyBag> bag;
@property (strong, nonatomic) NSMutableArray *drafts;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation MCLDraftTableViewController

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
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (!self) return nil;

    self.bag = bag;
    [self draftsChanged:nil];
    [self configureNotifications];

    return self;
}

- (void)configureNotifications
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(themeChanged:)
                               name:MCLThemeChangedNotification
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(draftsChanged:)
                               name:MCLDraftsChangedNotification
                             object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UIViewController life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"draft_vc_title", nil);
    [self configureEditButton];
    [self configureTableView];
    [self configureToolbar];
}

#pragma mark - Configuration

- (void)configureEditButton
{
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    BOOL isEnabled = [self.drafts count] > 0;
    self.navigationItem.rightBarButtonItem.enabled = isEnabled;
    if (!isEnabled) {
        self.editing = NO;
    }
}

- (void)configureTableView
{
    UINib *messageCellNib = [UINib nibWithNibName:@"MCLDraftTableViewCell" bundle:nil];
    [self.tableView registerNib:messageCellNib forCellReuseIdentifier:MCLDraftTableViewCellIdentifier];
}

- (void)configureToolbar
{
    [self.navigationController setToolbarHidden:YES animated:NO];
    self.navigationController.toolbar.hidden = YES;
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.drafts count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MCLDraftTableViewCell *cell = (MCLDraftTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"DraftCell" forIndexPath:indexPath];
    cell.bag = self.bag;
    cell.draft = self.drafts[indexPath.section];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle != UITableViewCellEditingStyleDelete) {
        return;
    }
    
    MCLDraft *deletedDraft = self.drafts[indexPath.section];
    [self.drafts removeObjectAtIndex:indexPath.section];
    [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];

    MCLMessage *deletedMessage = [MCLMessage messageFromDraft:deletedDraft];
    [self.bag.draftManager removeDraftForMessage:deletedMessage];

    [self configureEditButton];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    MCLDraft *draft = self.drafts[section];
    return [self.dateFormatter stringFromDate:draft.date];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MCLDraft *selectedDraft = self.drafts[indexPath.section];
    if (selectedDraft) {
        MCLComposeMessageViewController *composeMessageVC = [self.bag.router modalToEditDraft:selectedDraft];
        composeMessageVC.delegate = self;
    }
}

#pragma mark - MCLComposeMessageViewControllerDelegate

- (void)composeMessageViewController:(MCLComposeMessageViewController *)composeMessageViewController dismissedWithMessage:(MCLMessage *)message
{
    [self deselectSelectedRow];
}

- (void)composeMessageViewController:(MCLComposeMessagePreviewViewController *)composeMessageViewController sentMessage:(MCLMessage *)message
{
    [self deselectSelectedRow];
    [self draftsChanged:nil];
    [self.tableView reloadData];
}

- (void)deselectSelectedRow
{
    NSIndexPath *selectedPath = self.tableView.indexPathForSelectedRow;
    if (selectedPath) {
        [self.tableView deselectRowAtIndexPath:selectedPath animated:YES];
    }
}

#pragma mark - Notifications

- (void)themeChanged:(NSNotification *)notification
{
    [self.tableView reloadData];
}

- (void)draftsChanged:(NSNotification *)notification
{
    self.drafts = [self.bag.draftManager.all mutableCopy];
    if (notification) {
        [self.tableView reloadData];
    }
}

@end

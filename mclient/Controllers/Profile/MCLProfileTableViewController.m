//
//  MCLProfileTableViewController.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLProfileTableViewController.h"

#import "MCLDependencyBag.h"
#import "MCLTheme.h"
#import "MCLThemeManager.h"
#import "MCLUser.h"

@interface MCLProfileTableViewController ()

@property (strong, nonatomic) UIImage *profileImage;

@end

@implementation MCLProfileTableViewController

#pragma mark - Initializers

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - ViewController life cycle

- (void)awakeFromNib
{
    [super awakeFromNib];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(themeChanged:)
                                                 name:MCLThemeChangedNotification
                                               object:nil];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if ([self.delegate respondsToSelector:@selector(handleRotationChangeInBackground)]) {
        [self.delegate handleRotationChangeInBackground];
    }
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
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.profileData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *key = self.profileKeys[indexPath.row];
    static NSString *cellIdentifier = @"ProfileCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];

    if ([key isEqualToString:@"picture"]) {
        [cell.textLabel setHidden:YES];
        [cell.detailTextLabel setHidden:YES];

        if (self.profileImage) {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:self.profileImage];
            [imageView.layer setBorderColor:[[self.bag.themeManager.currentTheme tableViewSeparatorColor] CGColor]];
            [imageView.layer setBorderWidth:0.5f];

            CGRect imageViewFrame = imageView.frame;
            imageViewFrame.origin = CGPointMake(16.0f, 5.0f);
            imageView.frame = imageViewFrame;

            [cell.contentView addSubview:imageView];
        }
    } else {
        [cell.textLabel setHidden:NO];
        [cell.detailTextLabel setHidden:NO];

        cell.textLabel.text = [NSLocalizedString(key, nil) stringByAppendingString:@":"];

        cell.detailTextLabel.textColor = [self.bag.themeManager.currentTheme detailTextColor];

        NSString *detailText = [self.profileData objectForKey:key];
        cell.detailTextLabel.text = detailText.length ? detailText : @"-";

        for (id subview in cell.contentView.subviews) {
            if ([[subview class] isSubclassOfClass: [UIImageView class]]) {
                [subview removeFromSuperview];
            }
        }
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height;
    NSString *key = self.profileKeys[indexPath.row];
    if ([key isEqualToString:@"picture"]) {
        if (!self.profileImage && [self.profileData objectForKey:@"picture"]) {
            NSString *imageURLString = [self.profileData objectForKey:key];
            if (imageURLString.length) {
                NSURL *imageURL = [NSURL URLWithString:imageURLString];
                self.profileImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageURL]];
            }
        }

        height = self.profileImage ? self.profileImage.size.height + 10 : 0;
    } else {
        NSString *cellText = [self.profileData objectForKey:key];
        CGFloat labelHeight = [cellText boundingRectWithSize:CGSizeMake(self.view.bounds.size.width - 30, MAXFLOAT)
                                                     options:NSStringDrawingUsesLineFragmentOrigin
                                                  attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14.0]}
                                                     context:nil].size.height;
        height = labelHeight + 30;
    }

    return height;
}

#pragma mark - Actions

- (void)doneButtonPressed:(UIBarButtonItem *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Notifications

- (void)themeChanged:(NSNotification *)notification
{
    [self.tableView setSeparatorColor:[self.bag.themeManager.currentTheme tableViewSeparatorColor]];
    [self.tableView reloadData];
}

@end

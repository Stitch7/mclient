//
//  MCLProfileTableViewController.m
//  mclient
//
//  Created by Christopher Reitz on 06.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLProfileTableViewController.h"

#import "MCLAppDelegate.h"
#import "MCLMServiceConnector.h"
#import "MCLTheme.h"
#import "MCLThemeManager.h"
#import "MCLLoadingView.h"
#import "MCLInternetConnectionErrorView.h"
#import "MCLMServiceErrorView.h"

@interface MCLProfileTableViewController ()

@property (strong, nonatomic) id <MCLTheme> currentTheme;
@property (strong, nonatomic) NSArray *profileKeys;
@property (strong, nonatomic) NSMutableDictionary *profileData;
@property (strong, nonatomic) UIImage *profileImage;

@end

@implementation MCLProfileTableViewController


#pragma mark - Accessors

@synthesize profileKeys = _profileKeys;

- (NSArray *)profileKeys
{
    if (!_profileKeys) {
        _profileKeys = @[@"picture",
                         @"firstname",
                         @"lastname",
                         @"domicile",
                         @"accountNo",
                         @"registrationDate",
                         @"email",
                         @"icq",
                         @"homepage",
                         @"firstGame",
                         @"allTimeClassics",
                         @"favoriteGenres",
                         @"currentSystems",
                         @"hobbies",
                         @"xboxLiveGamertag",
                         @"psnId",
                         @"nintendoFriendcode",
                         @"lastUpdate"];
    }

    return _profileKeys;
}

#pragma mark - ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.currentTheme = [[MCLThemeManager sharedManager] currentTheme];
    self.title = self.username;

    // Hide the tableView separators to avoid flickering loading view
    [self.tableView setSeparatorColor:[UIColor clearColor]];

    // Visualize loading
    [self.view addSubview:[[MCLLoadingView alloc] initWithFrame:self.view.frame]];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    // Load data async
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *mServiceError;
        NSDictionary *data = [[MCLMServiceConnector sharedConnector] userWithId:self.userId error:&mServiceError];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self fetchedData:data error:mServiceError];
        });
    });
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.tableView reloadData];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if ([self.delegate respondsToSelector:@selector(handleRotationChangeInBackground)]) {
        [self.delegate handleRotationChangeInBackground];
    }
}

#pragma mark - Data methods

- (void)fetchedData:(NSDictionary *)data error:(NSError *)error
{
    for (id subview in self.view.subviews) {
        if ([[subview class] isSubclassOfClass: [MCLErrorView class]] ||
            [[subview class] isSubclassOfClass: [MCLLoadingView class]]
        ) {
            [subview removeFromSuperview];
        }
    }
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    if (error) {
        switch (error.code) {
            case -2:
                [self.view addSubview:[[MCLInternetConnectionErrorView alloc] initWithFrame:self.view.frame]];
                break;

            default:
                [self.view addSubview:[[MCLMServiceErrorView alloc] initWithFrame:self.view.frame
                                                                          andText:[error localizedDescription]]];
                break;
        }
    } else {
        self.profileData = [NSMutableDictionary dictionary];
        for (NSString *key in self.profileKeys) {
            [self.profileData setObject:[data objectForKey:key] forKey:key];
        }

        NSDateFormatter *dateFormatterForInput = [[NSDateFormatter alloc] init];
        NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        [dateFormatterForInput setLocale:enUSPOSIXLocale];
        [dateFormatterForInput setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];

        NSDateFormatter *dateFormatterForOutput = [[NSDateFormatter alloc] init];
        [dateFormatterForOutput setDoesRelativeDateFormatting:YES];
        [dateFormatterForOutput setDateStyle:NSDateFormatterShortStyle];
        [dateFormatterForOutput setTimeStyle:NSDateFormatterShortStyle];

        NSString *dateString;
        for (NSString *key in @[@"registrationDate", @"lastUpdate"]) {
            dateString = [data objectForKey:key];
            if ([dateString length] > 0) {
                dateString = [dateFormatterForOutput stringFromDate:[dateFormatterForInput dateFromString:dateString]];
                [self.profileData setObject:dateString forKey:key];
            }
        }

        // Restore tables separatorColor
        [self.tableView setSeparatorColor:[self.currentTheme tableViewSeparatorColor]];

        [self.tableView reloadData];
    }
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
            [imageView.layer setBorderColor:[[self.currentTheme tableViewSeparatorColor] CGColor]];
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

        cell.detailTextLabel.textColor = [self.currentTheme detailTextColor];

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
        if (!self.profileImage && [[self.profileData objectForKey:@"picture"] length]) {
            NSString *imageURLString = [self.profileData objectForKey:key];
            if (imageURLString.length) {
                [self.profileData setObject:@"" forKey:key];
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

- (IBAction)doneAction:(UIBarButtonItem *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

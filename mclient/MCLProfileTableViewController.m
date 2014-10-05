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
#import "MCLLoadingView.h"
#import "MCLInternetConnectionErrorView.h"
#import "MCLMServiceErrorView.h"

@interface MCLProfileTableViewController ()

@property (strong) NSDictionary *profileData;
@property (strong) NSDictionary *profileLabels;
@property (strong) NSArray *profileKeys;
@property (strong) UIImage *profileImage;

@end

@implementation MCLProfileTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.username;
    
    self.profileKeys = @[@"image",
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
    
    self.profileLabels = @{@"image": @"Avatar",
                           @"firstname": @"Firstname",
                           @"lastname": @"Lastname",
                           @"domicile": @"Domicile",
                           @"accountNo": @"Account-No.",
                           @"registrationDate": @"Date of registration",
                           @"email": @"Email",
                           @"icq": @"ICQ",
                           @"homepage": @"Homepage",
                           @"firstGame": @"First Game",
                           @"allTimeClassics": @"All Time Classics",
                           @"favoriteGenres": @"Favorite Genres",
                           @"currentSystems": @"Current Systems",
                           @"hobbies": @"Hobbies",
                           @"xboxLiveGamertag": @"XBox Live Gamertag",
                           @"psnId": @"Playstation Network ID",
                           @"nintendoFriendcode": @"Nintendo Friendcode",
                           @"lastUpdate": @"Last Updated on"};

    // Visualize loading
    CGRect fullScreenFrame = [(MCLAppDelegate *)[[UIApplication sharedApplication] delegate] fullScreenFrameFromViewController:self];
    [self.view addSubview:[[MCLLoadingView alloc] initWithFrame:fullScreenFrame]];
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
        CGRect fullScreenFrame = [(MCLAppDelegate *)[[UIApplication sharedApplication] delegate] fullScreenFrameFromViewController:self];
        switch (error.code) {
            case -2:
                [self.view addSubview:[[MCLInternetConnectionErrorView alloc] initWithFrame:fullScreenFrame]];
                break;

            case -1:
                [self.view addSubview:[[MCLMServiceErrorView alloc] initWithFrame:fullScreenFrame andText:[error localizedDescription]]];
                break;

            default:
                [self.view addSubview:[[MCLMServiceErrorView alloc] initWithFrame:fullScreenFrame]];
                break;
        }
    } else {
        self.profileData = data;

        [self.tableView reloadData];
    }
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.profileData count] - 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *key = self.profileKeys[indexPath.row];
    static NSString *cellIdentifier = @"ProfileCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    if ([key isEqualToString:@"image"]) {
        cell.textLabel.text = @"";
        cell.detailTextLabel.text = @"";
        
        if (self.profileImage) {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:self.profileImage];
            [imageView.layer setBorderColor:[[UIColor lightGrayColor] CGColor]];
            [imageView.layer setBorderWidth:0.5];

            CGRect imageViewFrame = imageView.frame;
            imageViewFrame.origin = CGPointMake(20.0f, 5.0f);
            imageView.frame = imageViewFrame;

            [cell.contentView addSubview:imageView];
        }
    } else {
        cell.textLabel.text = [[self.profileLabels objectForKey:key] stringByAppendingString:@":"];
        
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
    
    if ([key isEqualToString:@"image"]) {
        if ( ! self.profileImage && [self.profileData objectForKey:@"image"] != [NSNull null]) {
            NSString *imageURLString = [self.profileData objectForKey:key];
            if (imageURLString.length) {
                NSURL *imageURL = [NSURL URLWithString:imageURLString];
                self.profileImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageURL]];
            }
        }

        height = self.profileImage ? self.profileImage.size.height + 10 : 0;
    } else {
        NSString *cellText = [self.profileData objectForKey:key];

        CGSize labelSize = [cellText boundingRectWithSize:CGSizeMake(280.0f, MAXFLOAT)
                                       options:NSStringDrawingUsesLineFragmentOrigin
                                    attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:14.0]}
                                       context:nil].size;
        
        height = labelSize.height + 30;
    }

    return height;
}


#pragma mark - Actions

- (IBAction)doneAction:(UIBarButtonItem *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

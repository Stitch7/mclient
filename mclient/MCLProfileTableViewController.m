//
//  MCLProfileTableViewController.m
//  mclient
//
//  Created by Christopher Reitz on 06.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "constants.h"
#import "MCLProfileTableViewController.h"

@interface MCLProfileTableViewController ()

@property (strong) NSDictionary *profileData;
@property (strong) NSDictionary *profileLabels;
@property (strong) NSArray *profileKeys;
@property (strong) UIImage *profileImage;

@end

@implementation MCLProfileTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.username;
    
    self.profileKeys = @[@"image",
                         @"firstname",
                         @"lastname",
                         @"domicile",
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
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *urlString = [kMServiceBaseURL stringByAppendingString:[NSString stringWithFormat:@"profile/%@", self.userId]];
        NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString: urlString]];
        [self performSelectorOnMainThread:@selector(fetchedData:) withObject:data waitUntilDone:YES];
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Data methods

- (void)fetchedData:(NSData *)responseData
{
    NSError* error;
    self.profileData = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
    
    [self.tableView reloadData];
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ProfileCell" forIndexPath:indexPath];
    
    if ([key isEqualToString:@"image"]) {
        cell.textLabel.text = @"";
        cell.detailTextLabel.text = @"";
        
        if (self.profileImage) {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:self.profileImage];
            imageView.tag = 777; //TODO
            
            [imageView.layer setBorderColor:[[UIColor lightGrayColor] CGColor]];
            [imageView.layer setBorderWidth:0.5];
            
            CGRect imageViewFrame = imageView.frame;
            imageViewFrame.origin = CGPointMake(cell.textLabel.frame.origin.x, cell.textLabel.frame.origin.y);
            imageView.frame = imageViewFrame;
            
            [cell.contentView addSubview:imageView];
        }
    } else {
        cell.textLabel.text = [[self.profileLabels objectForKey:key] stringByAppendingString:@":"];
        
        NSString *detailText = [self.profileData objectForKey:key];
        cell.detailTextLabel.text = detailText.length ? detailText : @"-";
        
        UIView *imageView = [cell.contentView viewWithTag:777];
        if (imageView) {
            [imageView removeFromSuperview];
        }
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height;
    NSString *key = self.profileKeys[indexPath.row];
    
    if ([key isEqualToString:@"image"]) {
        if ( ! self.profileImage) {
            NSString *imageURLString = [self.profileData objectForKey:key];
            if (imageURLString.length) {
                NSURL *imageURL = [NSURL URLWithString:imageURLString];
                self.profileImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageURL]]; //TODO Replace with UIWebView to support animated GIFs
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


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

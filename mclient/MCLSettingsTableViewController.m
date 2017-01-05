//
//  MCLSettingsTableViewController.m
//  mclient
//
//  Created by Christopher Reitz on 01.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "constants.h"
#import "KeychainItemWrapper.h"
#import "MCLSettingsTableViewController.h"
#import "MCLMServiceConnector.h"

@interface MCLSettingsTableViewController ()

@property (strong, nonatomic) KeychainItemWrapper *keychainItem;

@property (weak, nonatomic) NSUserDefaults *userDefaults;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *settingsDoneButton;
@property (weak, nonatomic) IBOutlet UITextField *settingsUsernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *settingsPasswordTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *settingsLoginDataStatusSpinner;
@property (weak, nonatomic) IBOutlet UILabel *settingsLoginDataStatusLabel;
@property (weak, nonatomic) IBOutlet UITableViewCell *settingsLoginDataStatusTableViewCell;
@property (weak, nonatomic) IBOutlet UISwitch *settingsSignatureEnabledSwitch;
@property (weak, nonatomic) IBOutlet UITextView *settingsSignatureTextView;
@property (strong, nonatomic) NSNumber *threadView;
@property (strong, nonatomic) NSNumber *showImages;
@property (assign, nonatomic) BOOL loginDataChanged;
@property (strong, nonatomic) NSString *lastUsernameTextFieldValue;
@property (strong, nonatomic) NSString *lastPasswordTextFieldValue;
@property (weak, nonatomic) IBOutlet UISwitch *jumpToLatestMessageSwitch;

@end

@implementation MCLSettingsTableViewController

#define THREADVIEW_SECTION 2;
#define IMAGES_SECTION 3;
#define OPTIONS_SECTION 4;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.userDefaults = [NSUserDefaults standardUserDefaults];
    
    // Reading username + password from keychain
    NSString *keychainIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    self.keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:keychainIdentifier accessGroup:nil];
    [self.keychainItem setObject:(__bridge id)(kSecAttrAccessibleWhenUnlocked) forKey:(__bridge id)(kSecAttrAccessible)];
    NSData *passwordData = [self.keychainItem objectForKey:(__bridge id)(kSecValueData)];
    NSString *password = [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];
    NSString *username = [self.keychainItem objectForKey:(__bridge id)(kSecAttrAccount)];
    self.settingsUsernameTextField.text = username;
    self.settingsPasswordTextField.text = password;
    self.lastUsernameTextFieldValue = username;
    self.lastPasswordTextFieldValue = password;
    self.settingsUsernameTextField.delegate = self;
    self.settingsPasswordTextField.delegate = self;
    self.loginDataChanged = NO;

    [self.settingsLoginDataStatusTableViewCell setTintColor:[UIColor colorWithRed:75/255.0 green:216/255.0 blue:99/255.0 alpha:1.0]];
    [self.settingsLoginDataStatusTableViewCell setAccessoryType:UITableViewCellAccessoryNone];
    self.settingsLoginDataStatusSpinner.transform = CGAffineTransformMakeScale(0.75, 0.75);
    self.settingsLoginDataStatusLabel.text = @"";
    [self testLogin];

    if ([self.userDefaults objectForKey:@"signatureEnabled"] == nil) {
        self.settingsSignatureEnabledSwitch.on = YES;
        [self settingsSignatureEnabledSwitchValueChangedAction:self.settingsSignatureEnabledSwitch];
    } else {
        self.settingsSignatureEnabledSwitch.on = [self.userDefaults boolForKey:@"signatureEnabled"];
    }
    [self signatureTextViewEnabled:self.settingsSignatureEnabledSwitch.on];
    self.settingsSignatureTextView.delegate = self;
    self.settingsSignatureTextView.text = [self.userDefaults objectForKey:@"signature"] ?: kSettingsSignatureTextDefault;

    self.threadView = [self.userDefaults objectForKey:@"threadView"] ?: @(kMCLSettingsThreadViewWidmann);
    self.showImages = [self.userDefaults objectForKey:@"showImages"] ?: @(kMCLSettingsShowImagesAlways);

    self.jumpToLatestMessageSwitch.on = [self.userDefaults boolForKey:@"jumpToLatestPost"];

    UILabel *aboutLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 50)];
    aboutLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    aboutLabel.numberOfLines = 2;
    aboutLabel.font = [UIFont systemFontOfSize:13.0f];
    aboutLabel.textAlignment = NSTextAlignmentCenter;
    aboutLabel.textColor = [UIColor darkGrayColor];

    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    aboutLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Version %@ (%@)\nCopyright © 2014-2017 Christopher Reitz aka Stitch", nil),
                       [infoDictionary objectForKey:@"CFBundleShortVersionString"],
                       [infoDictionary objectForKey:@"CFBundleVersion"]];

    self.tableView.tableFooterView = aboutLabel;

}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    if (self.loginDataChanged) {
        [self.delegate settingsTableViewControllerDidFinish:self];
    }
    [self.userDefaults synchronize];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)testLogin
{
    NSString *username = self.settingsUsernameTextField.text;
    NSString *password = self.settingsPasswordTextField.text;
    
    if (username.length > 0 && password.length > 0) {
        [self.settingsLoginDataStatusTableViewCell setAccessoryType:UITableViewCellAccessoryNone];
        self.settingsLoginDataStatusLabel.textColor = [UIColor darkGrayColor];
        self.settingsLoginDataStatusLabel.text = NSLocalizedString(@"Verifying username and password…", nil);
        [self.settingsLoginDataStatusSpinner startAnimating];

        [self.keychainItem setObject:username forKey:(__bridge id)(kSecAttrAccount)];
        [self.keychainItem setObject:password forKey:(__bridge id)(kSecValueData)];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError *mServiceError;
            [[MCLMServiceConnector sharedConnector] testLoginWithUsername:username password:password error:&mServiceError];

            dispatch_async(dispatch_get_main_queue(), ^{
                [self.settingsLoginDataStatusSpinner stopAnimating];
                
                if (mServiceError) {
                    [self.settingsLoginDataStatusTableViewCell setAccessoryType:UITableViewCellAccessoryNone];
                    self.settingsLoginDataStatusLabel.textColor = [UIColor redColor];

                    if ([mServiceError code] == 401) {
                        self.settingsLoginDataStatusLabel.text = NSLocalizedString(@"Login data was entered incorrectly", nil);
                    } else {
                        self.settingsLoginDataStatusLabel.text = NSLocalizedString(@"Error: Could not connect to server", nil);
                    }
                } else {
                    [self.settingsLoginDataStatusTableViewCell setAccessoryType:UITableViewCellAccessoryCheckmark];
                    self.settingsLoginDataStatusLabel.text = NSLocalizedString(@"Login data is valid", nil);
                }
            });
        });
    } else {
        [self.settingsLoginDataStatusTableViewCell setAccessoryType:UITableViewCellAccessoryNone];
        self.settingsLoginDataStatusLabel.textColor = [UIColor darkGrayColor];
        self.settingsLoginDataStatusLabel.text = NSLocalizedString(@"Please enter username and password", nil);
    }
}

- (void)signatureTextViewEnabled:(BOOL)enable
{
    // Color can only be changed if TextView is editable!
    if (enable) {
        [self.settingsSignatureTextView setEditable:YES];
        [self.settingsSignatureTextView setSelectable:YES];
        [self.settingsSignatureTextView setTextColor:[UIColor blackColor]];
    } else {
        [self.settingsSignatureTextView setTextColor:[UIColor lightGrayColor]];
        [self.settingsSignatureTextView setEditable:NO];
        [self.settingsSignatureTextView setSelectable:NO];
    }
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];

    int threadViewSection = THREADVIEW_SECTION;
    int imagesSection = IMAGES_SECTION;

    if (indexPath.section == threadViewSection) {
        if ([self.threadView integerValue] == indexPath.row) {
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        } else {
            [cell setAccessoryType:UITableViewCellAccessoryNone];
        }
    } else if (indexPath.section == imagesSection) {
        if ([self.showImages integerValue] == indexPath.row) {
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        } else {
            [cell setAccessoryType:UITableViewCellAccessoryNone];
        }
    } else {
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }

    return cell;
}

#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int threadViewSection = THREADVIEW_SECTION;
    if (indexPath.section == threadViewSection) {
        for (int row = 0; row < [self.tableView numberOfRowsInSection:threadViewSection]; row++) {
            NSIndexPath *cellPath = [NSIndexPath indexPathForRow:row inSection:threadViewSection];
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:cellPath];
            if (row == indexPath.row) {
                [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
                self.threadView = @(row);
                [self.userDefaults setInteger:row forKey:@"threadView"];
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            } else {
                [cell setAccessoryType:UITableViewCellAccessoryNone];
            }
        }
    }

    int imagesSection = IMAGES_SECTION;
    if (indexPath.section == imagesSection) {
        for (int row = 0; row < [self.tableView numberOfRowsInSection:imagesSection]; row++) {
            NSIndexPath *cellPath = [NSIndexPath indexPathForRow:row inSection:imagesSection];
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:cellPath];
            if (row == indexPath.row) {
                [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
                self.showImages = @(row);
                [self.userDefaults setInteger:row forKey:@"showImages"];
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            } else {
                [cell setAccessoryType:UITableViewCellAccessoryNone];
            }
        }
    }
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.settingsUsernameTextField) {
        [textField resignFirstResponder];
        [self.settingsPasswordTextField becomeFirstResponder];
    }

    if (textField == self.settingsPasswordTextField) {
        [textField resignFirstResponder];
        [self.settingsUsernameTextField becomeFirstResponder];
    }

    return NO;
}

#pragma mark - UITextViewDelegate

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if (textView == self.settingsSignatureTextView) {
        [self.userDefaults setObject:textView.text forKey:@"signature"];
    }
}


#pragma mark - Actions

- (IBAction)settingsDoneAction:(UIBarButtonItem *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)settingsUsernameEditingDidEndAction:(UITextField *)sender
{
    if ( ! [sender.text isEqualToString:self.lastUsernameTextFieldValue]) {
        [self testLogin];
        self.loginDataChanged = YES;
    }
    self.lastUsernameTextFieldValue = sender.text;
}

- (IBAction)settingsPasswordEditingDidEndAction:(UITextField *)sender
{
    if ( ! [sender.text isEqualToString:self.lastPasswordTextFieldValue]) {
        [self testLogin];
        self.loginDataChanged = YES;
    }
    self.lastPasswordTextFieldValue = sender.text;
}

- (IBAction)settingsSignatureEnabledSwitchValueChangedAction:(UISwitch *)sender
{
    [self.userDefaults setBool:sender.on forKey:@"signatureEnabled"];
    [self signatureTextViewEnabled:sender.on];

}

- (IBAction)jumpToLatestPostEnabledSwitchValueChangedAction:(UISwitch *)sender {
    [self.userDefaults setBool:sender.on forKey:@"jumpToLatestPost"];
}

@end

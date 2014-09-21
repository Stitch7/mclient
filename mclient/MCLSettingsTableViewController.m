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
@property (weak, nonatomic) IBOutlet UISwitch *settingsSignatureEnabledSwitch;
@property (weak, nonatomic) IBOutlet UITextView *settingsSignatureTextView;
@property (weak, nonatomic) IBOutlet UISwitch *settingsNightModeSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *settingsSyncReadStatusSwitch;

@property (assign, nonatomic) int threadView;
@property (assign, nonatomic) int showImages;

@end

@implementation MCLSettingsTableViewController

#define THREADVIEW_SECTION 2;
#define IMAGES_SECTION 3;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.userDefaults = [NSUserDefaults standardUserDefaults];
    
    // Reading username + password from keychain
    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    self.keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:identifier accessGroup:nil];
    [self.keychainItem setObject:(__bridge id)(kSecAttrAccessibleWhenUnlocked) forKey:(__bridge id)(kSecAttrAccessible)];
    NSData *passwordData = [self.keychainItem objectForKey:(__bridge id)(kSecValueData)];
    NSString *password = [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];
    NSString *username = [self.keychainItem objectForKey:(__bridge id)(kSecAttrAccount)];
    
    self.settingsUsernameTextField.text = username;
    self.settingsPasswordTextField.text = password;

    BOOL signatureEnabled = [self.userDefaults boolForKey:@"signatureEnabled"];
    self.settingsSignatureEnabledSwitch.on = signatureEnabled;
    [self signatureTextViewEnabled:signatureEnabled];

    self.settingsSignatureTextView.delegate = self;
    self.settingsSignatureTextView.text = [self.userDefaults objectForKey:@"signature"] ?: @"sent from M!client for iOS";

    self.settingsNightModeSwitch.on = [self.userDefaults boolForKey:@"nightMode"];
    self.settingsSyncReadStatusSwitch.on = [self.userDefaults boolForKey:@"syncReadStatus"];

    int threadViewSection = THREADVIEW_SECTION;
    self.threadView = [self.userDefaults integerForKey:@"threadView"];
    self.threadView = self.threadView ? self.threadView : kMCLSettingsThreadViewDefault;

    int imagesSection = IMAGES_SECTION;
    self.showImages = [self.userDefaults integerForKey:@"showImages"];
    self.showImages = self.showImages ? self.showImages : kMCLSettingsShowImagesAlways;

    for (int section = 0; section < [self.tableView numberOfSections]; section++) {
        for (int row = 0; row < [self.tableView numberOfRowsInSection:section]; row++) {
            NSIndexPath* cellPath = [NSIndexPath indexPathForRow:row inSection:section];
            UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:cellPath];

            if (section == threadViewSection) {
                if (self.threadView == row) {
                    [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
                } else {
                    [cell setAccessoryType:UITableViewCellAccessoryNone];
                }
            } else if (section == imagesSection) {
                if (self.showImages == row) {
                    [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
                } else {
                    [cell setAccessoryType:UITableViewCellAccessoryNone];
                }
            } else {
                [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            }
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
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
        NSString *title, *message;
        
        MCLMServiceConnector *mServiceConnector = [[MCLMServiceConnector alloc] init];
        NSError *error;
        
        if ([mServiceConnector testLoginWIthUsername:username password:password error:&error]) {
            [self.keychainItem setObject:username forKey:(__bridge id)(kSecAttrAccount)];
            [self.keychainItem setObject:password forKey:(__bridge id)(kSecValueData)];
            title = @"Login succeed";
            message = @"You credentials have been securely saved into the keychain of this device";
        } else {
            title = @"Login failed";
            message = @"Please verifiy username and password";
        }
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int threadViewSection = THREADVIEW_SECTION;
    if (indexPath.section == threadViewSection) {
        for (int row = 0; row < [self.tableView numberOfRowsInSection:threadViewSection]; row++) {
            NSIndexPath* cellPath = [NSIndexPath indexPathForRow:row inSection:threadViewSection];
            UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:cellPath];
            if (row == indexPath.row) {
                [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
                self.threadView = row;
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
            NSIndexPath* cellPath = [NSIndexPath indexPathForRow:row inSection:imagesSection];
            UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:cellPath];
            if (row == indexPath.row) {
                [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
                self.showImages = row;
                [self.userDefaults setInteger:row forKey:@"showImages"];
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            } else {
                [cell setAccessoryType:UITableViewCellAccessoryNone];
            }
        }
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


#pragma mark - Actions

- (IBAction)settingsDoneAction:(UIBarButtonItem *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)settingsUsernameEditingDidEndAction:(UITextField *)sender
{
    [self.userDefaults setObject:sender.text forKey:@"username"];
    [self testLogin];
}

- (IBAction)settingsPasswordEditingDidEndAction:(UITextField *)sender
{
    [self.userDefaults setObject:sender.text forKey:@"password"];
    [self testLogin];
}

- (IBAction)settingsSignatureEnabledSwitchValueChangedAction:(UISwitch *)sender
{
    [self.userDefaults setBool:sender.on forKey:@"signatureEnabled"];
    [self signatureTextViewEnabled:sender.on];

}

- (IBAction)settingsNightModeSwitchValueChangedAction:(UISwitch *)sender
{
    [self.userDefaults setBool:sender.on forKey:@"nightMode"];
}

- (IBAction)settingsSyncReadStatusSwitchValueChangedAction:(UISwitch *)sender
{
    [self.userDefaults setBool:sender.on forKey:@"syncReadStatus"];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if (textView == self.settingsSignatureTextView) {
        [self.userDefaults setObject:textView.text forKey:@"signature"];
    }
}

@end

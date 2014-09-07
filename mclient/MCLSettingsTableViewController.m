//
//  MCLSettingsTableViewController.m
//  mclient
//
//  Created by Christopher Reitz on 01.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

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

@end

@implementation MCLSettingsTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    if (self = [super initWithStyle:style]) {
        // Custom initialization
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.userDefaults = [NSUserDefaults standardUserDefaults];
    
    // Reading username + password from keychain
    self.keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:@"M!client" accessGroup:nil];
    [self.keychainItem setObject:(__bridge id)(kSecAttrAccessibleWhenUnlocked) forKey:(__bridge id)(kSecAttrAccessible)];
    NSData *passwordData = [self.keychainItem objectForKey:(__bridge id)(kSecValueData)];
    NSString *password = [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];
    NSString *username = [self.keychainItem objectForKey:(__bridge id)(kSecAttrAccount)];
    NSLog(@"read from keychain: username=%@ - password=%@", username, password);

    
    self.settingsUsernameTextField.text = username;
    self.settingsPasswordTextField.text = password;
    self.settingsSignatureEnabledSwitch.on = [self.userDefaults boolForKey:@"signatureEnabled"];
    self.settingsNightModeSwitch.on = [self.userDefaults boolForKey:@"nightMode"];
    self.settingsSyncReadStatusSwitch.on = [self.userDefaults boolForKey:@"syncReadStatus"];
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
        if ([mServiceConnector testLoginWIthUsername:username password:password]) {
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
    NSLog(@"DidEndEditing");
}

@end

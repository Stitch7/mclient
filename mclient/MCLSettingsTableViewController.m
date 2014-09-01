//
//  MCLSettingsTableViewController.m
//  mclient
//
//  Created by Christopher Reitz on 01.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLSettingsTableViewController.h"

@interface MCLSettingsTableViewController ()

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
    
    self.settingsUsernameTextField.text = [self.userDefaults objectForKey:@"username"];
    self.settingsPasswordTextField.text = [self.userDefaults objectForKey:@"password"];
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

#pragma mark - Actions

- (IBAction)settingsDoneAction:(UIBarButtonItem *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)settingsUsernameEditingDidEndAction:(UITextField *)sender
{
    [self.userDefaults setObject:sender.text forKey:@"username"];
}

- (IBAction)settingsPasswordEditingDidEndAction:(UITextField *)sender
{
    [self.userDefaults setObject:sender.text forKey:@"password"];
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

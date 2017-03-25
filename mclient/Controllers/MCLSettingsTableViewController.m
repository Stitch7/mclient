//
//  MCLSettingsTableViewController.m
//  mclient
//
//  Created by Christopher Reitz on 01.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//
#import "MCLSettingsTableViewController.h"

#import "constants.h"
#import "MCLAppDelegate.h"
#import "KeychainItemWrapper.h"
#import "MCLMServiceConnector.h"
#import "MCLNotificationManager.h"
#import "MCLThemeManager.h"
#import "MCLDefaultTheme.h"
#import "MCLNightTheme.h"
#import "MCLTextView.h"

@interface MCLSettingsTableViewController ()

@property (strong, nonatomic) KeychainItemWrapper *keychainItem;
@property (strong, nonatomic) MCLThemeManager *themeManager;
@property (strong, nonatomic) NSUserDefaults *userDefaults;
@property (strong, nonatomic) NSNumber *threadView;
@property (strong, nonatomic) NSNumber *showImages;
@property (assign, nonatomic) BOOL loginDataChanged;
@property (strong, nonatomic) NSString *lastUsernameTextFieldValue;
@property (strong, nonatomic) NSString *lastPasswordTextFieldValue;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *settingsDoneButton;
@property (weak, nonatomic) IBOutlet UITextField *settingsUsernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *settingsPasswordTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *settingsLoginDataStatusSpinner;
@property (weak, nonatomic) IBOutlet UILabel *settingsLoginDataStatusLabel;
@property (weak, nonatomic) IBOutlet UITableViewCell *settingsLoginDataStatusTableViewCell;
@property (weak, nonatomic) IBOutlet UISwitch *backgroundNotificationsEnabledSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *settingsSignatureEnabledSwitch;
@property (weak, nonatomic) IBOutlet MCLTextView *settingsSignatureTextView;
@property (weak, nonatomic) IBOutlet UISwitch *jumpToLatestMessageSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *nightModeEnabledSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *nightModeAutomaticallySwitch;

@end

@implementation MCLSettingsTableViewController

#define THREADVIEW_SECTION 3;
#define FONTSIZE_SECTION 5;
#define IMAGES_SECTION 6;

-(void)awakeFromNib
{
    [super awakeFromNib];

    self.userDefaults = [NSUserDefaults standardUserDefaults];
    self.themeManager = [MCLThemeManager sharedManager];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self configureDismissKeyboardEvent];
    [self configureLoginSection];
    [self configureNotificationsSection];
    [self configureSignatureSection];
    [self configureThreadSection];
    [self configureNightModeSection];
    [self configureAboutLabel];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    [self.delegate settingsTableViewControllerDidFinish:self loginDataChanged:self.loginDataChanged];
}

- (void)configureDismissKeyboardEvent
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:tap];
}

- (void)configureNotificationsSection
{
    BOOL backgroundNotificationsEnabled = [[MCLNotificationManager sharedNotificationManager] backgroundNotificationsEnabled];
    self.backgroundNotificationsEnabledSwitch.on = backgroundNotificationsEnabled;
    [self setbackgroundNotificationsEnabledSwitchEnabled:backgroundNotificationsEnabled];
}

- (void)setbackgroundNotificationsEnabledSwitchEnabled:(BOOL)enabled
{
    BOOL isRegistered = [[MCLNotificationManager sharedNotificationManager] backgroundNotificationsRegistered];
    if (enabled || isRegistered) {
        self.backgroundNotificationsEnabledSwitch.enabled = YES;
        self.backgroundNotificationsEnabledSwitch.alpha = 1.0f;
    }
    else {
        self.backgroundNotificationsEnabledSwitch.enabled = NO;
        self.backgroundNotificationsEnabledSwitch.alpha = 0.6f;
    }
}

- (void)configureNightModeSection
{
    BOOL nightModeEnabled = [self.userDefaults boolForKey:@"nightModeEnabled"];
    BOOL nightModeAutomatically = [self.userDefaults boolForKey:@"nightModeAutomatically"];

    self.nightModeEnabledSwitch.on = nightModeEnabled;
    self.nightModeAutomaticallySwitch.on = nightModeAutomatically;

    if (nightModeEnabled) {
        self.nightModeAutomaticallySwitch.enabled = NO;
        self.nightModeAutomaticallySwitch.alpha = 0.6f;
    }

    if (nightModeAutomatically) {
        self.nightModeEnabledSwitch.enabled = NO;
        self.nightModeEnabledSwitch.alpha = 0.6f;
    }
}

- (void)configureImagesSection
{
    self.showImages = [self.userDefaults objectForKey:@"showImages"] ?: @(kMCLSettingsShowImagesAlways);
}

- (void)configureThreadSection
{
    self.threadView = [self.userDefaults objectForKey:@"threadView"] ?: @(kMCLSettingsThreadViewWidmann);
    self.jumpToLatestMessageSwitch.on = [self.userDefaults boolForKey:@"jumpToLatestPost"];
}

-(void)configureLoginSection
{
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

    NSDictionary<NSString *,id> *placeholderAttrs = @{NSForegroundColorAttributeName: [UIColor lightGrayColor]};
    NSAttributedString *usernamePlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Username", nil)
                                                                              attributes:placeholderAttrs];
    NSAttributedString *passwordPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Password", nil)
                                                                              attributes:placeholderAttrs];
    self.settingsUsernameTextField.attributedPlaceholder = usernamePlaceholder;
    self.settingsPasswordTextField.attributedPlaceholder = passwordPlaceholder;

    self.settingsUsernameTextField.delegate = self;
    self.settingsPasswordTextField.delegate = self;
    self.loginDataChanged = NO;

    [self.settingsLoginDataStatusTableViewCell setTintColor:[UIColor colorWithRed:75/255.0 green:216/255.0 blue:99/255.0 alpha:1.0]];
    [self.settingsLoginDataStatusTableViewCell setAccessoryType:UITableViewCellAccessoryNone];
    self.settingsLoginDataStatusSpinner.transform = CGAffineTransformMakeScale(0.75, 0.75);
    self.settingsLoginDataStatusLabel.text = @"";
    [self testLogin];
}

- (void)testLogin
{
    id <MCLTheme> theme = self.themeManager.currentTheme;
    NSString *username = self.settingsUsernameTextField.text;
    NSString *password = self.settingsPasswordTextField.text;

    if (username.length > 0 && password.length > 0) {
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
                    self.settingsLoginDataStatusLabel.textColor = [theme warnTextColor];

                    if ([mServiceError code] == 401) {
                        self.settingsLoginDataStatusLabel.text = NSLocalizedString(@"Login data was entered incorrectly", nil);
                    } else {
                        self.settingsLoginDataStatusLabel.text = NSLocalizedString(@"Error: Could not connect to server", nil);
                    }
                    [self setbackgroundNotificationsEnabledSwitchEnabled:NO];
                } else {
                    self.settingsLoginDataStatusLabel.textColor = [theme successTextColor];
                    self.settingsLoginDataStatusLabel.text = NSLocalizedString(@"Login data is valid", nil);
                    [self setbackgroundNotificationsEnabledSwitchEnabled:YES];
                }
            });
        });
    } else {
        [self.settingsLoginDataStatusTableViewCell setAccessoryType:UITableViewCellAccessoryNone];
        self.settingsLoginDataStatusLabel.textColor = [UIColor darkGrayColor];
        self.settingsLoginDataStatusLabel.text = NSLocalizedString(@"Please enter username and password", nil);
    }
}

- (void)configureSignatureSection
{
    if ([self.userDefaults objectForKey:@"signatureEnabled"] == nil) {
        self.settingsSignatureEnabledSwitch.on = YES;
        [self settingsSignatureEnabledSwitchValueChangedAction:self.settingsSignatureEnabledSwitch];
    } else {
        self.settingsSignatureEnabledSwitch.on = [self.userDefaults boolForKey:@"signatureEnabled"];
    }
    [self signatureTextViewEnabled:self.settingsSignatureEnabledSwitch.on];
    self.settingsSignatureTextView.delegate = self;
    self.settingsSignatureTextView.text = [self.userDefaults objectForKey:@"signature"] ?: kSettingsSignatureTextDefault;
}

- (void)configureAboutLabel
{
    UILabel *aboutLabel = [[UILabel alloc] init];
    aboutLabel.numberOfLines = 2;
    aboutLabel.font = [UIFont systemFontOfSize:13.0f];
    aboutLabel.textAlignment = NSTextAlignmentCenter;
    aboutLabel.textColor = [UIColor darkGrayColor];

    NSString *aboutText = NSLocalizedString(@"Version %@ (%@)\nCopyright © 2014-2017 Christopher Reitz aka Stitch", nil);
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    aboutLabel.text = [NSString stringWithFormat:aboutText,
                       [infoDictionary objectForKey:@"CFBundleShortVersionString"],
                       [infoDictionary objectForKey:@"CFBundleVersion"]];

    self.tableView.tableFooterView = aboutLabel;
    [aboutLabel setNeedsLayout];
    [aboutLabel layoutIfNeeded];
    CGFloat height = [aboutLabel systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 40.0;

    // Update the header's frame and set it again
    CGRect headerFrame = aboutLabel.frame;
    headerFrame.size.height = height;
    aboutLabel.frame = headerFrame;
    self.tableView.tableFooterView = aboutLabel;
}

- (void)signatureTextViewEnabled:(BOOL)enable
{
    id <MCLTheme> theme = self.themeManager.currentTheme;
    // Color can only be changed if TextView is editable
    if (enable) {
        [self.settingsSignatureTextView setEditable:YES];
        [self.settingsSignatureTextView setSelectable:YES];
        [self.settingsSignatureTextView setTextColor:[theme textViewTextColor]];
    } else {
        [self.settingsSignatureTextView setTextColor:[theme textViewDisabledTextColor]];
        [self.settingsSignatureTextView setEditable:NO];
        [self.settingsSignatureTextView setSelectable:NO];
    }
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];

    UIView *backgroundView = [[UIView alloc] initWithFrame:cell.frame];
    backgroundView.backgroundColor = [self.themeManager.currentTheme tableViewCellSelectedBackgroundColor];

    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];

    int threadViewSection = THREADVIEW_SECTION;
    if (indexPath.section == threadViewSection) {
        if ([self.threadView integerValue] == indexPath.row) {
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        } else {
            [cell setAccessoryType:UITableViewCellAccessoryNone];
        }
        cell.selectedBackgroundView = backgroundView;
        [cell setSelectionStyle:UITableViewCellSelectionStyleDefault];
    }

    int fontSizeSection = FONTSIZE_SECTION;
    if (indexPath.section == fontSizeSection) {
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        [cell setSelectionStyle:UITableViewCellSelectionStyleDefault];

        cell.detailTextLabel.textColor = [[self.themeManager currentTheme] detailTextColor];
        NSString *detailText;
        NSInteger fontSize = [[NSUserDefaults standardUserDefaults] integerForKey:@"fontSize"];
        switch (fontSize) {
            case 1:
                detailText = NSLocalizedString(@"Tiny", nil);
                break;
            case 2:
                detailText = NSLocalizedString(@"Small", nil);
                break;
            default:
            case 3:
                detailText = NSLocalizedString(@"Normal", nil);
                break;
            case 4:
                detailText = NSLocalizedString(@"Big", nil);
                break;
            case 5:
                detailText = NSLocalizedString(@"Bigger", nil);
                break;
            case 6:
                detailText = NSLocalizedString(@"Huge", nil);
                break;
        }
        cell.detailTextLabel.text = detailText;
    }

    int imagesSection = IMAGES_SECTION;
    if (indexPath.section == imagesSection) {
        if ([self.showImages integerValue] == indexPath.row) {
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        } else {
            [cell setAccessoryType:UITableViewCellAccessoryNone];
        }
        cell.selectedBackgroundView = backgroundView;
        [cell setSelectionStyle:UITableViewCellSelectionStyleDefault];
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:[self.themeManager.currentTheme tableViewHeaderTextColor]];
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *footer = (UITableViewHeaderFooterView *)view;
    [footer.textLabel setTextColor:[self.themeManager.currentTheme tableViewFooterTextColor]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
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

#pragma mark - UITextViewDelegate

- (void)settingsFontSizeViewController:(MCLSettingsFontSizeViewController *)inController fontSizeChanged:(int)fontSize
{
    [self.tableView reloadData];
}

#pragma mark - Actions


- (void)dismissKeyboard
{
    [self.view endEditing:YES];
}

- (IBAction)settingsDoneAction:(UIBarButtonItem *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)settingsUsernameEditingDidEndAction:(UITextField *)sender
{
    if (![sender.text isEqualToString:self.lastUsernameTextFieldValue]) {
        [self testLogin];
        self.loginDataChanged = YES;
    }
    self.lastUsernameTextFieldValue = sender.text;
}

- (IBAction)settingsPasswordEditingDidEndAction:(UITextField *)sender
{
    if (![sender.text isEqualToString:self.lastPasswordTextFieldValue]) {
        [self testLogin];
        self.loginDataChanged = YES;
    }
    self.lastPasswordTextFieldValue = sender.text;
}

- (IBAction)backgroundNotificationsEnabledSwitchValueChangedAction:(UISwitch *)sender {
    [self.userDefaults setBool:sender.on forKey:@"backgroundNotifications"];
    if (sender.on) {
        [[MCLNotificationManager sharedNotificationManager] registerBackgroundNotifications];
    }
}

- (IBAction)settingsSignatureEnabledSwitchValueChangedAction:(UISwitch *)sender
{
    [self.userDefaults setBool:sender.on forKey:@"signatureEnabled"];
    [self signatureTextViewEnabled:sender.on];
}

- (IBAction)jumpToLatestPostEnabledSwitchValueChangedAction:(UISwitch *)sender {
    [self.userDefaults setBool:sender.on forKey:@"jumpToLatestPost"];
}

- (IBAction)nightModeEnabledSwitchValueChangedAction:(UISwitch *)sender
{
    [self.userDefaults setBool:sender.on forKey:@"nightModeEnabled"];

    if (sender.on) {
        self.nightModeAutomaticallySwitch.enabled = NO;
        self.nightModeAutomaticallySwitch.alpha = 0.6f;
        [self.userDefaults setBool:NO forKey:@"nightModeAutomatically"];
    }
    else {
        self.nightModeAutomaticallySwitch.enabled = YES;
        self.nightModeAutomaticallySwitch.alpha = 1.0f;
    }

    NSUInteger themeName = sender.on ? kMCLThemeNight : kMCLThemeDefault;
    [self.userDefaults setInteger:themeName forKey:@"theme"];

    [self.themeManager loadTheme];
    [self.tableView reloadData];
}

- (IBAction)nightModeAutomaticallySwitchValueChangedAction:(UISwitch *)sender
{
    [self.userDefaults setBool:sender.on forKey:@"nightModeAutomatically"];

    if (sender.on) {
        // Trigger dialog asking for location permission
        [self.themeManager updateSun];

        self.nightModeEnabledSwitch.enabled = NO;
        self.nightModeEnabledSwitch.alpha = 0.6f;
        [self.userDefaults setBool:NO forKey:@"nightModeEnabled"];
    }
    else {
        self.nightModeEnabledSwitch.enabled = YES;
        self.nightModeEnabledSwitch.alpha = 1.0f;
    }

    [self.themeManager loadTheme];
    [self.tableView reloadData];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"PushToSettingsFontSize"]) {
        MCLSettingsFontSizeViewController *settingsFontSizeVC = (MCLSettingsFontSizeViewController *)segue.destinationViewController;
        [settingsFontSizeVC setDelegate:self];
    }
}

@end

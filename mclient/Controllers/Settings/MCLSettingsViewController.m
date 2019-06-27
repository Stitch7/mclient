//
//  MCLSettingsViewController.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLSettingsViewController.h"

@import SafariServices;

#import "utils.h"
#import "UIApplication+Additions.h"
#import "MCLHTTPClient.h"
#import "MCLDependencyBag.h"
#import "MCLFeatures.h"
#import "MCLSettings.h"
#import "MCLRouter+openURL.h"
#import "MCLLoginManager.h"
#import "MCLNotificationManager.h"
#import "MCLThemeManager.h"
#import "MCLSoundEffectPlayer.h"
#import "MCLLightTheme.h"
#import "MCLDarkTheme.h"
#import "MCLTextField.h"
#import "MCLTextView.h"
#import "MCLSettingsFontSizeViewController.h"
#import "MCLLicenseTableViewController.h"
#import "MCLThreadKillfileViewController.h"

NSString * const MCLThreadViewStyleChangedNotification = @"ThreadViewStyleChangedNotification";

@interface MCLSettingsViewController ()

@property (strong, nonatomic) MCLThemeManager *themeManager;
@property (strong, nonatomic) NSNumber *threadView;
@property (strong, nonatomic) NSNumber *showImages;
@property (assign, nonatomic) BOOL loginDataChanged;
@property (strong, nonatomic) NSString *lastUsernameTextFieldValue;
@property (strong, nonatomic) NSString *lastPasswordTextFieldValue;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet MCLTextField *usernameTextField;
@property (weak, nonatomic) IBOutlet MCLTextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loginDataStatusSpinner;
@property (weak, nonatomic) IBOutlet UILabel *loginDataStatusLabel;
@property (weak, nonatomic) IBOutlet UITableViewCell *loginDataStatusTableViewCell;
@property (weak, nonatomic) IBOutlet UISwitch *backgroundNotificationsEnabledSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *settingsSignatureEnabledSwitch;
@property (weak, nonatomic) IBOutlet MCLTextView *settingsSignatureTextView;
@property (weak, nonatomic) IBOutlet UISwitch *jumpToLatestMessageSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *openLinksInSafariSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *embedYoutubeVideosSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *classicQuoteDesignSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *darkModeEnabledSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *darkModeAutomaticallySwitch;
@property (weak, nonatomic) IBOutlet UISwitch *soundEffectsEnabledSwitch;

@end

@implementation MCLSettingsViewController

#define THREADVIEW_SECTION 3;
#define FONTSIZE_SECTION 4;
#define IMAGES_SECTION 9;
#define INFO_SECTION 12;

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.modalPresentationStyle = UIModalPresentationFormSheet;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.themeManager = self.bag.themeManager;
    [self configureDismissKeyboardEvent];
    [self configureLoginSection];
    [self configureNotificationsSection];
    [self configureSignatureSection];
    [self configureThreadSection];
    [self configureDarkModeSection];
    [self configureImagesSection];
    [self configureMiscellaneousSection];
    [self configureAboutLabel];

//    if (![self.bag.features isFeatureWithNameEnabled:MCLFeatureKillFileThreads]) {
//        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:9] withRowAnimation:UITableViewRowAnimationNone];
//    }
}

- (void)configureDismissKeyboardEvent
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:tap];
}

- (void)configureNotificationsSection
{
    BOOL backgroundNotificationsEnabled = [self.bag.notificationManager backgroundNotificationsEnabled];
    self.backgroundNotificationsEnabledSwitch.on = backgroundNotificationsEnabled;
    [self setbackgroundNotificationsEnabledSwitchEnabled:backgroundNotificationsEnabled];
}

- (void)setbackgroundNotificationsEnabledSwitchEnabled:(BOOL)enabled
{
    BOOL loginValid = self.bag.loginManager.loginValid;
    BOOL wasAlreadyRegistered = [self.bag.settings isSettingActivated:MCLSettingBackgroundNotificationsRegistered];
    BOOL isRegistered = [self.bag.notificationManager backgroundNotificationsRegistered];
    if (loginValid && (enabled || !wasAlreadyRegistered || isRegistered)) {
        self.backgroundNotificationsEnabledSwitch.enabled = YES;
        self.backgroundNotificationsEnabledSwitch.alpha = 1.0f;
    } else {
        self.backgroundNotificationsEnabledSwitch.enabled = NO;
        self.backgroundNotificationsEnabledSwitch.alpha = 0.6f;
    }
}

- (void)configureDarkModeSection
{
    BOOL darkModeEnabled = [self.bag.settings isSettingActivated:MCLSettingDarkModeEnabled];
    BOOL darkModeAutomatically = [self.bag.settings isSettingActivated:MCLSettingDarkModeAutomatically];

    self.darkModeEnabledSwitch.on = darkModeEnabled;
    self.darkModeAutomaticallySwitch.on = darkModeAutomatically;

    if (darkModeEnabled) {
        self.darkModeAutomaticallySwitch.enabled = NO;
        self.darkModeAutomaticallySwitch.alpha = 0.6f;
    }

    if (darkModeAutomatically) {
        self.darkModeEnabledSwitch.enabled = NO;
        self.darkModeEnabledSwitch.alpha = 0.6f;
    }
}

- (void)configureImagesSection
{
    self.showImages = [self.bag.settings objectForSetting:MCLSettingShowImages
                                                orDefault:@(kMCLSettingsShowImagesAlways)];
}

- (void)configureThreadSection
{
    self.threadView = [self.bag.settings objectForSetting:MCLSettingThreadView
                                                orDefault:@(kMCLSettingsThreadViewWidmann)];
    self.jumpToLatestMessageSwitch.on = [self.bag.settings isSettingActivated:MCLSettingJumpToLatestPost];
    self.openLinksInSafariSwitch.on = [self.bag.settings isSettingActivated:MCLSettingOpenLinksInSafari];
    self.embedYoutubeVideosSwitch.on = [self.bag.settings isSettingActivated:MCLSettingEmbedYoutubeVideos];
    self.classicQuoteDesignSwitch.on = [self.bag.settings isSettingActivated:MCLSettingClassicQuoteDesign];
}

- (void)configureLoginSection
{
    NSString *username = self.bag.loginManager.username;
    NSString *password = self.bag.loginManager.password;

    self.usernameTextField.text = username;
    self.passwordTextField.text = password;
    self.lastUsernameTextFieldValue = username;
    self.lastPasswordTextFieldValue = password;

    NSDictionary<NSString *,id> *placeholderAttrs = @{NSForegroundColorAttributeName: [UIColor lightGrayColor]};
    NSAttributedString *usernamePlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Username", nil)
                                                                              attributes:placeholderAttrs];
    NSAttributedString *passwordPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Password", nil)
                                                                              attributes:placeholderAttrs];
    self.usernameTextField.attributedPlaceholder = usernamePlaceholder;
    self.passwordTextField.attributedPlaceholder = passwordPlaceholder;

    self.passwordTextField.clearButtonMode = UITextFieldViewModeWhileEditing;

    self.usernameTextField.delegate = self;
    self.passwordTextField.delegate = self;
    self.loginDataChanged = NO;

    [self.loginDataStatusTableViewCell setTintColor:[UIColor colorWithRed:75/255.0 green:216/255.0 blue:99/255.0 alpha:1.0]];
    [self.loginDataStatusTableViewCell setAccessoryType:UITableViewCellAccessoryNone];
    self.loginDataStatusSpinner.transform = CGAffineTransformMakeScale(0.75, 0.75);
    self.loginDataStatusLabel.text = @"";
    [self testLogin];
}

- (void)testLogin
{
    id <MCLTheme> theme = self.themeManager.currentTheme;
    NSString *username = self.usernameTextField.text;
    NSString *password = self.passwordTextField.text;

    if (username.length > 0 && password.length > 0) {
        CGFloat loginDataStatusLabelFontSize = self.loginDataStatusLabel.font.pointSize;
        self.loginDataStatusLabel.font = [UIFont italicSystemFontOfSize:loginDataStatusLabelFontSize];
        self.loginDataStatusLabel.textColor = [UIColor darkGrayColor];
        self.loginDataStatusLabel.text = NSLocalizedString(@"Verifying username and password…", nil);
        [self.loginDataStatusSpinner startAnimating];

        [self.bag.loginManager updateUsername:username];
        [self.bag.loginManager updatePassword:password];

        [self.bag.loginManager performLoginWithCompletionHandler:^(NSError *error, BOOL success) {
            [self.loginDataStatusSpinner stopAnimating];
            self.loginDataStatusLabel.font = [UIFont systemFontOfSize:loginDataStatusLabelFontSize];
            if (success) {
                self.loginDataStatusLabel.textColor = [theme successTextColor];
                self.loginDataStatusLabel.text = NSLocalizedString(@"Login data is valid", nil);
                [self setbackgroundNotificationsEnabledSwitchEnabled:YES];
            } else {
                self.loginDataStatusLabel.textColor = [theme warnTextColor];

                if ([error code] == MCLHTTPErrorCodeInvalidLogin) {
                    self.loginDataStatusLabel.text = NSLocalizedString(@"Login data was entered incorrectly", nil);
                    [self.bag.soundEffectPlayer playLoginFailedSound];
                } else {
                    self.loginDataStatusLabel.text = NSLocalizedString(@"Error: Could not connect to server", nil);
                }
                [self setbackgroundNotificationsEnabledSwitchEnabled:NO];
            }
        }];
    } else {
        [self.bag.loginManager performLogout];
        [self.loginDataStatusTableViewCell setAccessoryType:UITableViewCellAccessoryNone];
        self.loginDataStatusLabel.textColor = [UIColor darkGrayColor];
        self.loginDataStatusLabel.text = NSLocalizedString(@"Please enter username and password", nil);
    }
}

- (void)configureSignatureSection
{
    // TODO: That's an relict from plain UserDefaults times
    if ([self.bag.settings objectForSetting:MCLSettingSignatureEnabled] == nil) {
        self.settingsSignatureEnabledSwitch.on = YES;
        self.settingsSignatureEnabledSwitch.tag = 1;
        [self signatureEnabledSwitchValueChangedAction:self.settingsSignatureEnabledSwitch];
    } else {
        self.settingsSignatureEnabledSwitch.on = [self.bag.settings isSettingActivated:MCLSettingSignatureEnabled];
    }
    [self signatureTextViewEnabled:self.settingsSignatureEnabledSwitch.on];
    self.settingsSignatureTextView.delegate = self;
    self.settingsSignatureTextView.themeManager = self.bag.themeManager;

    self.settingsSignatureTextView.text = [self.bag.settings objectForSetting:MCLSettingSignatureText
                                                                    orDefault:kSettingsSignatureTextDefault];
}

- (void)configureMiscellaneousSection
{
    self.soundEffectsEnabledSwitch.on = [self.bag.settings isSettingActivated:MCLSettingSoundEffectsEnabled orDefault:YES];
}

- (void)configureAboutLabel
{
    UILabel *aboutLabel = [[UILabel alloc] init];
    aboutLabel.numberOfLines = 2;
    aboutLabel.font = [UIFont systemFontOfSize:13.0f];
    aboutLabel.textAlignment = NSTextAlignmentCenter;
    aboutLabel.textColor = [UIColor darkGrayColor];

    NSString *aboutText = @"Version %@ (%@)\nCopyright © 2014-%@ Christopher Reitz aka Stitch";
    NSDateFormatter *yearFormatter = [[NSDateFormatter alloc] init];
    [yearFormatter setDateFormat:@"yyyy"];
    NSString *yearString = [yearFormatter stringFromDate:[NSDate date]];
    aboutLabel.text = [NSString stringWithFormat:aboutText, [self.bag.application version], [self.bag.application buildNumber], yearString];

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
        switch ([self.bag.settings integerForSetting:MCLSettingFontSize]) {
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
    const int threadViewSection = THREADVIEW_SECTION;
    const int imagesSection = IMAGES_SECTION;
    const int infoSection = INFO_SECTION;

    switch (indexPath.section) {
        case threadViewSection:
            [self didSelectRowInThreadViewSectionAtIndexPath:indexPath];
            break;

        case imagesSection:
            [self didSelectRowInImagesSectionAtIndexPath:indexPath];
            break;

        case infoSection:
            [self didSelectRowInInfoSectionAtIndexPath:indexPath];
            break;
    }
}

- (void)didSelectRowInThreadViewSectionAtIndexPath:(NSIndexPath *)indexPath
{
    int threadViewSection = THREADVIEW_SECTION;
    for (int row = 0; row < [self.tableView numberOfRowsInSection:threadViewSection]; row++) {
        NSIndexPath *cellPath = [NSIndexPath indexPathForRow:row inSection:threadViewSection];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:cellPath];
        if (row == indexPath.row) {
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
            self.threadView = @(row);
            [self.bag.settings setInteger:row forSetting:MCLSettingThreadView];
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        } else {
            [cell setAccessoryType:UITableViewCellAccessoryNone];
        }
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:MCLThreadViewStyleChangedNotification object:self];
}

- (void)didSelectRowInImagesSectionAtIndexPath:(NSIndexPath *)indexPath
{
    int imagesSection = IMAGES_SECTION;
    for (int row = 0; row < [self.tableView numberOfRowsInSection:imagesSection]; row++) {
        NSIndexPath *cellPath = [NSIndexPath indexPathForRow:row inSection:imagesSection];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:cellPath];
        if (row == indexPath.row) {
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
            self.showImages = @(row);
            [self.bag.settings setInteger:row forSetting:MCLSettingShowImages];
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        } else {
            [cell setAccessoryType:UITableViewCellAccessoryNone];
        }
    }
}

- (void)didSelectRowInInfoSectionAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
            [self openLegalDocument:@"terms.html"];
            break;

        case 1:
            [self openLegalDocument:@"privacy.html"];
            break;

        case 2:
            [self openLegalDocument:@"imprint.html"];
            break;

        case 3:
            [self.navigationController pushViewController:[[MCLLicenseTableViewController alloc] initWithBag:self.bag]
                                                 animated:YES];
            break;

        case 4:
            [self openUrl:@"https://github.com/Stitch7/mclient"];
            break;

        case 5:
            [self openUrl:@"https://github.com/Stitch7/mservice-webextension"];
            break;
    }
}

- (void)openUrl:(NSString *)urlString
{
    NSURL *url = [NSURL URLWithString:urlString];
    [self.bag.router pushToURL:url fromPresentingViewController:self];
}

- (void)openLegalDocument:(NSString *)document
{
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@", kManiacForumURL, document]];
    [self.bag.router openRawManiacForumURL:url fromPresentingViewController:self];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.usernameTextField) {
        [textField resignFirstResponder];
        [self.passwordTextField becomeFirstResponder];
    }

    if (textField == self.passwordTextField) {
        [textField resignFirstResponder];
        [self.usernameTextField becomeFirstResponder];
    }

    return NO;
}

#pragma mark - UITextViewDelegate

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if (textView == self.settingsSignatureTextView) {
        [self.bag.settings setObject:textView.text forSetting:MCLSettingSignatureText];
    }
}

#pragma mark - MCLSettingsFontSizeViewControllerDelegate

- (void)settingsFontSizeViewController:(MCLSettingsFontSizeViewController *)inController fontSizeChanged:(int)fontSize
{
    [self.tableView reloadData];
}

#pragma mark - Actions

- (void)dismissKeyboard
{
    [self.view endEditing:YES];
}

- (IBAction)doneAction:(UIBarButtonItem *)sender
{
    [self.bag.settings reportSettingsIfChanged];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)usernameEditingDidEndAction:(UITextField *)sender
{
    NSString *input = [sender.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    if (![input isEqualToString:sender.text]) {
        sender.text = input;
    }

    if (![input isEqualToString:self.lastUsernameTextFieldValue]) {
        [self testLogin];
        self.loginDataChanged = YES;
    }

    self.lastUsernameTextFieldValue = input;
}

- (IBAction)passwordEditingDidEndAction:(UITextField *)sender
{
    if (![sender.text isEqualToString:self.lastPasswordTextFieldValue]) {
        [self testLogin];
        self.loginDataChanged = YES;
    }
    self.lastPasswordTextFieldValue = sender.text;
}

- (IBAction)backgroundNotificationsEnabledSwitchValueChangedAction:(UISwitch *)sender
{
    [self.bag.settings setBool:sender.on forSetting:MCLSettingBackgroundNotifications];
    if (sender.on) {
        [self.bag.notificationManager registerBackgroundNotifications];
    }
    [self.bag.soundEffectPlayer playSwitchSound];
}

- (IBAction)signatureEnabledSwitchValueChangedAction:(UISwitch *)sender
{
    [self.bag.settings setBool:sender.on forSetting:MCLSettingSignatureEnabled];
    [self signatureTextViewEnabled:sender.on];
    if (sender.tag == 0) {
        [self.bag.soundEffectPlayer playSwitchSound];
    }
    sender.tag = 0;
}

- (IBAction)jumpToLatestPostEnabledSwitchValueChangedAction:(UISwitch *)sender
{
    [self.bag.settings setBool:sender.on forSetting:MCLSettingJumpToLatestPost];
    [self.bag.soundEffectPlayer playSwitchSound];
}

- (IBAction)openLinksInSafariEnabledSwitchValueChangedAction:(UISwitch *)sender
{
    [self.bag.settings setBool:sender.on forSetting:MCLSettingOpenLinksInSafari];
    [self.bag.soundEffectPlayer playSwitchSound];
}

- (IBAction)embedYoutubeVideosEnabledSwitchValueChangedAction:(UISwitch *)sender
{
    [self.bag.settings setBool:sender.on forSetting:MCLSettingEmbedYoutubeVideos];
    [self.bag.soundEffectPlayer playSwitchSound];
}

- (IBAction)classicQuoteDesignEnabledSwitchValueChangedAction:(UISwitch *)sender
{
    [self.bag.settings setBool:sender.on forSetting:MCLSettingClassicQuoteDesign];
    [self.bag.soundEffectPlayer playSwitchSound];
}

- (IBAction)darkModeEnabledSwitchValueChangedAction:(UISwitch *)sender
{
    [self.bag.settings setBool:sender.on forSetting:MCLSettingDarkModeEnabled];
    [self.bag.soundEffectPlayer playSwitchSound];

    if (sender.on) {
        self.darkModeAutomaticallySwitch.enabled = NO;
        self.darkModeAutomaticallySwitch.alpha = 0.6f;
        [self.bag.settings setBool:NO forSetting:MCLSettingDarkModeAutomatically];
    } else {
        self.darkModeAutomaticallySwitch.enabled = YES;
        self.darkModeAutomaticallySwitch.alpha = 1.0f;
    }

    NSUInteger themeName = sender.on ? kMCLThemeDark : kMCLThemeLight;
    [self.bag.settings setInteger:themeName forSetting:MCLSettingTheme];

    [self.themeManager loadTheme];
    [self.tableView reloadData];
}

- (IBAction)darkModeAutomaticallySwitchValueChangedAction:(UISwitch *)sender
{
    [self.bag.settings setBool:sender.on forSetting:MCLSettingDarkModeAutomatically];
    [self.bag.soundEffectPlayer playSwitchSound];

    if (sender.on) {
        // Trigger dialog asking for location permission
        [self.themeManager updateSun];

        self.darkModeEnabledSwitch.enabled = NO;
        self.darkModeEnabledSwitch.alpha = 0.6f;
        [self.bag.settings setBool:NO forSetting:MCLSettingDarkModeEnabled];
    } else {
        self.darkModeEnabledSwitch.enabled = YES;
        self.darkModeEnabledSwitch.alpha = 1.0f;
    }

    [self.themeManager loadTheme];
    [self.tableView reloadData];
}

- (IBAction)soundEffectsEnabledSwitchValueChangedAction:(UISwitch *)sender
{
    [self.bag.settings setBool:sender.on forSetting:MCLSettingSoundEffectsEnabled];
    [self.bag.soundEffectPlayer playSwitchSound];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"PushToSettingsFontSize"]) {
        MCLSettingsFontSizeViewController *fontSizeVC = (MCLSettingsFontSizeViewController *)segue.destinationViewController;
        fontSizeVC.bag = self.bag;
        fontSizeVC.delegate = self;
    }
//    else if ([segue.identifier isEqualToString:@"PushToThreadsKillfile"]) {
//        MCLThreadKillfileViewController *killfileThreadsVC = (MCLThreadKillfileViewController *)segue.destinationViewController;
//        killfileThreadsVC.bag = self.bag;
//    }
}

@end

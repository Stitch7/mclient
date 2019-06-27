//
//  MCLAppDependencyBag.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@import HockeySDK;

#import "MCLAppDependencyBag.h"

#import <ImgurSession.h>
#import <Valet.h>

#import "VALValet+LoginSecureStore.h"
#import "MCLAppRouterDelegate.h"
#import "MCLFeatures.h"
#import "MCLSettings.h"
#import "MCLRouter.h"
#import "MCLLogin.h"
#import "MCLLoginManager.h"
#import "MCLThemeManager.h"
#import "MCLKeyboardShortcutManager.h"
#import "MCLSoundEffectPlayer.h"
#import "MCLFoundationHTTPClient.h"
#import "MCLNotificationManager.h"
#import "MCLDraftManager.h"
#import "MCLPrivateMessagesManager.h"
#import "MCLStoreReviewManager.h"
#import "MCLLaunchViewController.h"
#import "MCLBoardListTableViewController.h"

@interface MCLAppDependencyBag () <IMGSessionDelegate>

@end

@implementation MCLAppDependencyBag

@synthesize application;
@synthesize features;
@synthesize loginManager;
@synthesize httpClient;
@synthesize router;
@synthesize settings;
@synthesize notificationManager;
@synthesize themeManager;
@synthesize keyboardShortcutManager;
@synthesize draftManager;
@synthesize privateMessagesManager;
@synthesize storeReviewManager;
@synthesize soundEffectPlayer;

#pragma mark - Initializer

- (instancetype)init
{
    self = [super init];
    if (!self) return nil;

    [self configure];

    return self;
}

#pragma mark - Configuration

- (void)configure
{
    self.application = [UIApplication sharedApplication];
    self.features = [[MCLFeatures alloc] initWithStage:FEATURE_STAGE];

    [self configureCrashReporter];

    id <MCLLoginSecureStore> secureStore = [[VALValet alloc] initWithIdentifier:[[NSBundle mainBundle] bundleIdentifier]
                                                                  accessibility:VALAccessibilityWhenUnlocked];
    MCLLogin *login = [[MCLLogin alloc] initWithSecureStore:secureStore];

    self.loginManager = [[MCLLoginManager alloc] initWithLogin:login bag:self];
    self.httpClient = [[MCLFoundationHTTPClient alloc] initWithLoginManager:self.loginManager];
    self.router = [[MCLRouter alloc] initWithBag:self];
    self.router.delegate = [[MCLAppRouterDelegate alloc] initWithBag:self];
    self.settings = [[MCLSettings alloc] initWithBag:self userDefaults:[NSUserDefaults standardUserDefaults]];
    self.notificationManager = [[MCLNotificationManager alloc] initWithBag:self];
    self.themeManager = [[MCLThemeManager alloc] initWithSettings:self.settings];
    self.keyboardShortcutManager = [[MCLKeyboardShortcutManager alloc] initWithBag:self];
    self.draftManager = [[MCLDraftManager alloc] init];
    self.privateMessagesManager = [[MCLPrivateMessagesManager alloc] initWithBag:self];
    self.storeReviewManager = [[MCLStoreReviewManager alloc] initWithSettings:self.settings];
    self.soundEffectPlayer = [[MCLSoundEffectPlayer alloc] initWithSettings:self.settings];

    [self.themeManager loadTheme];
    [self configureAnalytics];

    [IMGSession anonymousSessionWithClientID:IMGUR_ID withDelegate:self];
}

- (void)configureCrashReporter
{
    if (![self.features isFeatureWithNameEnabled:MCLFeatureCrashReporter]) {
        return;
    }

    BITHockeyManager *hockeyManager = [BITHockeyManager sharedHockeyManager];
    [hockeyManager configureWithIdentifier:HOCKEYAPP_ID];
    [hockeyManager.crashManager setCrashManagerStatus:BITCrashManagerStatusAlwaysAsk];
    [hockeyManager startManager];
    [hockeyManager.authenticator authenticateInstallation];
    [hockeyManager.updateManager checkForUpdate];
}

- (void)configureAnalytics
{
    
}

@end

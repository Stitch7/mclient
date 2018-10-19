//
//  MCLLoginManager.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLLoginManager.h"

#import "MCLDependencyBag.h"
#import "MCLLogin.h"
#import "MCLLoginRequest.h"


NSString * const MCLLoginStateDidChangeNotification = @"MCLLoginStateDidChangeNotification";
NSString * const MCLLoginStateKey = @"MCLLoginValid";
NSString * const MCLLoginInitialAttemptKey = @"InitialAttempt";

const NSInteger LoginRefreshTreshholdInMinutes = 5;

@interface MCLLoginManager ()

@property (strong, nonatomic) MCLLogin *login;
@property (strong, nonatomic) id <MCLDependencyBag> bag;
@property (strong, nonatomic) NSDate *timeEnteredBackground;
@property (assign, readwrite) BOOL initialAttempt;
@property (assign, readwrite) BOOL loginValid;

@end

@implementation MCLLoginManager

#pragma mark - Initializers

- (instancetype)initWithLogin:(MCLLogin *)login bag:(id <MCLDependencyBag>)bag
{
    self = [super init];
    if (!self) return nil;

    self.login = login;
    self.bag = bag;
    self.initialAttempt = YES;
    [self configureNotifications];

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Notifications

- (void)configureNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    self.timeEnteredBackground = [[NSDate alloc] init];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    if (!self.timeEnteredBackground) {
        return;
    }

    NSInteger minutesInBackground = [[[NSCalendar currentCalendar] components:NSCalendarUnitMinute
                                                                     fromDate:self.timeEnteredBackground
                                                                       toDate:[[NSDate alloc] init]
                                                                      options:0] minute];
    if (minutesInBackground >= LoginRefreshTreshholdInMinutes) {
        [self performLogin];
    }
}

#pragma mark - Public Methods

- (NSString *)username
{
    return self.login.username;
}

- (NSString *)password
{
    return self.login.password;
}

- (NSDictionary *)dictionaryWithLoginData
{
    if (!self.username || !self.password) {
        return nil;
    }

    return @{@"username":self.username,
             @"password":self.password};
}

- (void)updateUsername:(NSString *)username
{
    [self.login updateUsername:username];
}

- (void)updatePassword:(NSString *)password
{
    [self.login updatePassword:password];
}

- (void)performLogin
{
    [self performLoginWithCompletionHandler:nil];
}

- (void)performLoginWithCompletionHandler:(void (^)(NSError*, BOOL))completionHandler
{
    if ([self.login credentialsAreInvalid]) {
        self.loginValid = NO;
        [self postLoginStateDidChangeNotification];
        if (completionHandler) {
            completionHandler(nil, NO);
        }
        return;
    }

    MCLLoginRequest *loginRequest = [[MCLLoginRequest alloc] initWithClient:self.bag.httpClient];
    [loginRequest loadWithCompletionHandler:^(NSError *error, NSArray *data) {
        BOOL success = !error;
        self.loginValid = success;
        [self postLoginStateDidChangeNotification];

        if (completionHandler) {
            completionHandler(error, success);
        }
    }];
}

- (void)performLogout
{
    [self.login reset];
    self.loginValid = NO;
    [self postLoginStateDidChangeNotification];
}

#pragma mark - Private Methods

- (void)postLoginStateDidChangeNotification
{
    NSDictionary *userInfo = @{MCLLoginStateKey:[NSNumber numberWithBool:self.loginValid],
                               MCLLoginInitialAttemptKey:[NSNumber numberWithBool:self.initialAttempt]};
    [[NSNotificationCenter defaultCenter] postNotificationName:MCLLoginStateDidChangeNotification
                                                        object:self
                                                      userInfo:userInfo];

    self.initialAttempt = NO;
}


@end

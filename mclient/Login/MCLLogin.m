//
//  MCLLogin.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLLogin.h"

#import <Valet.h>
#import "MCLDependencyBag.h"
#import "MCLLoginRequest.h"

NSString * const MCLLoginStateDidChangeNotification = @"MCLLoginStateDidChangeNotification";
NSString * const MCLLoginStateKey = @"MCLLoginValid";
NSString * const MCLLoginInitialAttemptKey = @"InitialAttempt";
NSString * const MCLLoginUsernameKey = @"username";
NSString * const MCLLoginPasswordKey = @"password";

@interface MCLLogin ()

@property (strong, nonatomic) id <MCLDependencyBag> bag;
@property (assign, readwrite) BOOL initialAttempt;
@property (assign, readwrite) BOOL valid;
@property (strong, nonatomic) VALValet *valet;

@end

@implementation MCLLogin

#pragma mark - Initializers

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag
{
    self = [super init];
    if (!self) return nil;

    self.bag = bag;
    [self configure];

    return self;
}

#pragma mark - Lazy properties

- (NSString *)username
{
    if (!_username) {
        _username = [self.valet stringForKey:MCLLoginUsernameKey];
    }

    return _username;
}

- (void)updateUsername:(NSString *)username
{
    _username = username;
    [self.valet setString:username forKey:MCLLoginUsernameKey];
}

- (NSString *)password
{
    if (!_password) {
        _password = [self.valet stringForKey:MCLLoginPasswordKey];
    }

    return _password;
}

- (void)updatePassword:(NSString *)password
{
    _password = password;
    [self.valet setString:password forKey:MCLLoginPasswordKey];
}

- (void)logout
{
    _username = nil;
    _password = nil;
    [self.valet removeObjectForKey:MCLLoginUsernameKey];
    [self.valet removeObjectForKey:MCLLoginPasswordKey];
    self.valid = NO;
    [self postLoginStateDidChangeNotification];
}

#pragma mark - Configuration

- (void)configure
{
    self.initialAttempt = YES;
    self.valid = NO;
    NSString *keychainIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    self.valet = [[VALValet alloc] initWithIdentifier:keychainIdentifier accessibility:VALAccessibilityWhenUnlocked];
}

#pragma mark - Public Methods

- (NSDictionary *)loginData
{
    if (!self.username || !self.password) {
        return nil;
    }

    return @{@"username":self.username,
             @"password":self.password};
}

- (void)testLoginWithCompletionHandler:(void (^)(NSError*, BOOL))completionHandler
{
    if ([self credentialsAreInvalid]) {
        self.valid = NO;
        [self postLoginStateDidChangeNotification];
        if (completionHandler) {
            completionHandler(nil, NO);
        }
        return;
    }

    MCLLoginRequest *loginRequest = [[MCLLoginRequest alloc] initWithClient:self.bag.httpClient login:self];
    [loginRequest loadWithCompletionHandler:^(NSError *error, NSArray *data) {
        BOOL success = !error;
        self.valid = success;
        [self postLoginStateDidChangeNotification];

        if (completionHandler) {
            completionHandler(error, success);
        }
    }];
}

#pragma mark - Private Methods

- (BOOL)credentialsAreInvalid
{
    return !self.username || !self.password || self.username.length == 0 || self.password.length == 0;
}

- (void)postLoginStateDidChangeNotification
{
    NSDictionary *userInfo = @{MCLLoginStateKey:[NSNumber numberWithBool:self.valid],
                               MCLLoginInitialAttemptKey:[NSNumber numberWithBool:self.initialAttempt]};
    [[NSNotificationCenter defaultCenter] postNotificationName:MCLLoginStateDidChangeNotification
                                                        object:self
                                                      userInfo:userInfo];

    self.initialAttempt = NO;
}

@end

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

@interface MCLLogin ()

@property (strong, nonatomic) id <MCLDependencyBag> bag;
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

- (NSString *)username {
    if (!_username) {
        _username = [self.valet stringForKey:@"username"];
    }

    return _username;
}

- (void)updateUsername:(NSString *)username
{
    _username = username;
    [self.valet setString:username forKey:@"username"];
}

- (NSString *)password {
    if (!_password) {
        _password = [self.valet stringForKey:@"password"];
    }

    return _password;
}

- (void)updatePassword:(NSString *)password
{
    _password = password;
    [self.valet setString:password forKey:@"password"];
}

#pragma mark - Configuration

- (void)configure
{
    NSString *keychainIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    self.valet = [[VALValet alloc] initWithIdentifier:keychainIdentifier accessibility:VALAccessibilityWhenUnlocked];
    self.valid = NO;
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
    if (!self.username || !self.password.length || self.username.length == 0 || self.password.length == 0) {
        self.valid = NO;
        completionHandler(nil, NO);
        return;
    }

    MCLLoginRequest *request = [[MCLLoginRequest alloc] initWithClient:self.bag.httpClient login:self];
    [request loadWithCompletionHandler:^(NSError *error, NSArray *data) {
        BOOL success = !error;
        self.valid = success;
        [self postLoginStateDidChangeNotification:success];

        if (completionHandler) {
            completionHandler(error, success);
        }
    }];
}

#pragma mark - Private Methods

- (void)postLoginStateDidChangeNotification:(BOOL)success
{
    NSDictionary *userInfo = @{MCLLoginStateKey:[NSNumber numberWithBool:success]};
    [[NSNotificationCenter defaultCenter] postNotificationName:MCLLoginStateDidChangeNotification
                                                        object:self
                                                      userInfo:userInfo];
}

@end

//
//  MCLLogin.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLLogin.h"

#import "MCLLoginSecureStore.h"


NSString * const MCLLoginUsernameKey = @"username";
NSString * const MCLLoginPasswordKey = @"password";

@interface MCLLogin ()

@property (strong, nonatomic) id <MCLLoginSecureStore> secureStore;

@end

@implementation MCLLogin

#pragma mark - Initializers

- (instancetype)initWithSecureStore:(id <MCLLoginSecureStore>)secureStore
{
    self = [super init];
    if (!self) return nil;

    self.secureStore = secureStore;

    return self;
}

#pragma mark - Lazy properties

- (NSString *)username
{
    if (!_username) {
        _username = [self.secureStore stringForKey:MCLLoginUsernameKey];
    }

    return _username;
}

- (void)updateUsername:(NSString *)username
{
    _username = username;
    [self.secureStore setString:username forKey:MCLLoginUsernameKey];
}

- (NSString *)password
{
    if (!_password) {
        _password = [self.secureStore stringForKey:MCLLoginPasswordKey];
    }

    return _password;
}

- (void)updatePassword:(NSString *)password
{
    _password = password;
    [self.secureStore setString:password forKey:MCLLoginPasswordKey];
}

#pragma mark - Public Methods

- (BOOL)credentialsAreInvalid
{
    return !self.username || !self.password || self.username.length == 0 || self.password.length == 0;
}

- (void)reset
{
    _username = nil;
    _password = nil;
    [self.secureStore removeObjectForKey:MCLLoginUsernameKey];
    [self.secureStore removeObjectForKey:MCLLoginPasswordKey];
}

@end

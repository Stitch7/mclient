//
//  MCLLogin.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLLoginSecureStore;

@interface MCLLogin : NSObject

@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *password;

- (instancetype)initWithSecureStore:(id <MCLLoginSecureStore>)secureStore;

- (void)updateUsername:(NSString *)username;
- (void)updatePassword:(NSString *)password;
- (BOOL)credentialsAreInvalid;
- (void)reset;

@end

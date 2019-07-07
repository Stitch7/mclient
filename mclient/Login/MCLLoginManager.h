//
//  MCLLoginManager.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLDependencyBag;
@class MCLLogin;

extern NSString * const MCLLoginStateDidChangeNotification;
extern NSString * const MCLLoginStateKey;
extern NSString * const MCLLoginInitialAttemptKey;

@interface MCLLoginManager : NSObject

@property (strong, readonly) NSString *username;
@property (strong, readonly) NSString *password;
@property (assign, readonly, getter=isLoginValid) BOOL loginValid;

- (instancetype)initWithLogin:(MCLLogin *)login bag:(id <MCLDependencyBag>)bag;

- (NSDictionary *)dictionaryWithLoginData;
- (void)updateUsername:(NSString *)username;
- (void)updatePassword:(NSString *)password;
- (void)performLogin;
- (void)performLoginWithCompletionHandler:(void (^)(NSError*, BOOL))completionHandler;
- (void)performLogout;

@end

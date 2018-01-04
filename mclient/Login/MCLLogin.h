//
//  MCLLogin.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

extern NSString * const MCLLoginStateDidChangeNotification;
extern NSString * const MCLLoginStateKey;

@protocol MCLDependencyBag;

@interface MCLLogin : NSObject

@property (assign, readonly) BOOL valid;
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *password;

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag;
- (NSDictionary *)loginData;
- (void)updateUsername:(NSString *)username;
- (void)updatePassword:(NSString *)password;
- (void)testLoginWithCompletionHandler:(void (^)(NSError*, BOOL))completionHandler;

@end

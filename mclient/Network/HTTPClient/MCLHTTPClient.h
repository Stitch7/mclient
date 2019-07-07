//
//  MCLHTTPClient.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@class MCLLoginManager;

static const NSInteger MCLHTTPErrorCodeNoInternetConnection = -2;
static const NSInteger MCLHTTPErrorCodeMServiceConnection = -1;
static const NSInteger MCLHTTPErrorCodeInvalidLogin = 401;

@protocol MCLHTTPClient <NSObject>

- (instancetype)initWithLoginManager:(MCLLoginManager *)loginManager;

- (void)getRequestToUrlString:(NSString *)urlString
                   needsLogin:(BOOL)needsLogin
            completionHandler:(void (^)(NSError *error, NSDictionary *json))completion;

- (void)postRequestToUrlString:(NSString *)urlString
                      withVars:(NSDictionary *)vars
                    needsLogin:(BOOL)needsLogin
             completionHandler:(void (^)(NSError *error, NSDictionary *json))completion;

- (void)postRequestToUrlString:(NSString *)urlString
                      withJSON:(NSDictionary *)json
                    needsLogin:(BOOL)needsLogin
             completionHandler:(void (^)(NSError *error, NSDictionary *json))completion;

- (void)putRequestToUrlString:(NSString *)urlString
                     withVars:(NSDictionary *)vars
                   needsLogin:(BOOL)needsLogin
            completionHandler:(void (^)(NSError *error, NSDictionary *json))completion;

- (void)putRequestToUrlString:(NSString *)urlString
                     withJSON:(NSDictionary *)json
                   needsLogin:(BOOL)needsLogin
            completionHandler:(void (^)(NSError *error, NSDictionary *json))completion;

- (void)deleteRequestToUrlString:(NSString *)urlString
                        withVars:(NSDictionary *)vars
                      needsLogin:(BOOL)needsLogin
               completionHandler:(void (^)(NSError *error, NSDictionary *json))completion;

@end

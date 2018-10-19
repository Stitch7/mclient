//
//  MCLHTTPClient.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@class MCLLoginManager;

@protocol MCLHTTPClient <NSObject>

- (instancetype)initWithLoginManager:(MCLLoginManager *)loginManager;

- (void)getRequestToUrlString:(NSString *)urlString
                   needsLogin:(BOOL)needsLogin
            completionHandler:(void (^)(NSError *error, NSDictionary *json))completion;

- (void)postRequestToUrlString:(NSString *)urlString
                      withVars:(NSDictionary *)vars
                    needsLogin:(BOOL)needsLogin
             completionHandler:(void (^)(NSError *error, NSDictionary *json))completion;

- (void)putRequestToUrlString:(NSString *)urlString
                     withVars:(NSDictionary *)vars
                   needsLogin:(BOOL)needsLogin
            completionHandler:(void (^)(NSError *error, NSDictionary *json))completion;

- (void)deleteRequestToUrlString:(NSString *)urlString
                        withVars:(NSDictionary *)vars
                      needsLogin:(BOOL)needsLogin
               completionHandler:(void (^)(NSError *error, NSDictionary *json))completion;

@end

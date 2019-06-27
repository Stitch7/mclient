//
//  MCLMarkUnreadResponsesAsReadRequest.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLMarkUnreadResponsesAsReadRequest.h"

#import "MCLHTTPClient.h"
#import "MCLLoginManager.h"

@interface MCLMarkUnreadResponsesAsReadRequest ()

@property (strong, nonatomic) MCLLoginManager *loginManager;

@end

@implementation MCLMarkUnreadResponsesAsReadRequest

@synthesize httpClient;

#pragma mark - Initializers

- (instancetype)initWithClient:(id <MCLHTTPClient>)httpClient loginManager:(MCLLoginManager *)loginManager
{
    self = [super init];
    if (!self) return nil;

    self.httpClient = httpClient;
    self.loginManager = loginManager;

    return self;
}

#pragma mark - MCLRequest

- (void)loadWithCompletionHandler:(void (^__nonnull)(NSError*, NSArray*))completionHandler
{
    NSString *urlString = [NSString stringWithFormat:@"%@/user/%@/mark-unread-responses-as-read",
                           kMServiceBaseURL, self.loginManager.username];
    [self.httpClient getRequestToUrlString:urlString
                                needsLogin:YES
                         completionHandler:^(NSError *error, NSDictionary *json) {
                             completionHandler(error, nil);
                         }];
}

@end

//
//  MCLMarkUnreadResponsesAsReadRequest.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLMarkUnreadResponsesAsReadRequest.h"

#import "MCLHTTPClient.h"
#import "MCLLogin.h"

@interface MCLMarkUnreadResponsesAsReadRequest ()

@property (strong, nonatomic) MCLLogin *login;

@end

@implementation MCLMarkUnreadResponsesAsReadRequest

@synthesize httpClient;

#pragma mark - Initializers

- (instancetype)initWithClient:(id <MCLHTTPClient>)httpClient login:(MCLLogin *)login
{
    self = [super init];
    if (!self) return nil;

    self.httpClient = httpClient;
    self.login = login;

    return self;
}

#pragma mark - MCLRequest

- (void)loadWithCompletionHandler:(void (^__nonnull)(NSError*, NSArray*))completionHandler
{
    NSString *urlString = [NSString stringWithFormat:@"%@/user/%@/mark-unread-responses-as-read",
                           kMServiceBaseURL, [self.login username]];
    [self.httpClient getRequestToUrlString:urlString
                                needsLogin:YES
                         completionHandler:^(NSError *error, NSDictionary *json) {
                             completionHandler(error, nil);
                         }];
}

@end

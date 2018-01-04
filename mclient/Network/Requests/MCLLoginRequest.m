//
//  MCLLoginRequest.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLLoginRequest.h"

#import "MCLHTTPClient.h"
#import "MCLLogin.h"

@interface MCLLoginRequest ()

@property (strong, nonatomic) MCLLogin *login;

@end

@implementation MCLLoginRequest

@synthesize httpClient;

#pragma mark - Initializers

- (instancetype)initWithClient:(id <MCLHTTPClient>)httpClient login:(MCLLogin *)login
{
    self = [super init];
    if (!self) {
        return nil;
    }

    self.httpClient = httpClient;
    self.login = login;

    return self;
}

#pragma mark - MCLRequest

- (void)loadWithCompletionHandler:(void (^__nonnull)(NSError*, NSArray*))completionHandler
{
    NSString *urlString = [NSString stringWithFormat:@"%@/test-login", kMServiceBaseURL];
    [self.httpClient getRequestToUrlString:urlString
                                needsLogin:YES
                         completionHandler:^(NSError *error, NSDictionary *json) {
                             completionHandler(error, [NSArray new]);
                         }];
}

@end

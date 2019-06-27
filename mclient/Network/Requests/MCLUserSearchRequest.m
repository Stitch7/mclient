//
//  MCLUserSearchRequest.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLUserSearchRequest.h"

#import "MCLHTTPClient.h"
#import "MCLUser.h"


@interface MCLUserSearchRequest ()

@property (strong, nonatomic) NSString *searchText;

@end

@implementation MCLUserSearchRequest

@synthesize httpClient;

#pragma mark - Initializers

- (instancetype)initWithClient:(id <MCLHTTPClient>)httpClient searchText:(NSString *)searchText
{
    self = [super init];
    if (!self) return nil;

    self.httpClient = httpClient;
    self.searchText = searchText;

    return self;
}

#pragma mark - MCLRequest

- (void)loadWithCompletionHandler:(void (^)(NSError*, NSArray*))completionHandler
{
    NSString *urlString = [NSString stringWithFormat:@"%@/user/search/%@", kMServiceBaseURL, self.searchText];
    [self.httpClient getRequestToUrlString:urlString
                                needsLogin:NO
                         completionHandler:^(NSError *error, NSDictionary *data) {
                             NSMutableArray *users;

                             if (!error) {
                                 users = [NSMutableArray array];
                                 for (NSDictionary *json in data) {
                                     MCLUser *user = [MCLUser userFromJSON:json];
                                     if (user) {
                                         [users addObject:user];
                                     }
                                 }
                             }

                             if (completionHandler) {
                                 completionHandler(error, users);
                             }
                         }];
}



@end

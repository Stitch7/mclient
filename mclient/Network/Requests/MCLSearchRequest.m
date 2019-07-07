//
//  MCLSearchRequest.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLSearchRequest.h"

#import "MCLHTTPClient.h"
#import "MCLMessage.h"
#import "MCLSearchQuery.h"

@interface MCLSearchRequest ()

@property (strong, nonatomic) MCLSearchQuery *searchQuery;

@end

@implementation MCLSearchRequest

@synthesize httpClient;

#pragma mark - Initializers

- (instancetype)initWithClient:(id <MCLHTTPClient>)httpClient searchQuery:(MCLSearchQuery *)searchQuery
{
    self = [super init];
    if (!self) return nil;

    self.httpClient = httpClient;
    self.searchQuery = searchQuery;

    return self;
}

#pragma mark - MCLRequest

- (void)loadWithCompletionHandler:(void (^)(NSError*, NSArray*))completionHandler
{
    NSString *urlString = [NSString stringWithFormat:@"%@/search", kMServiceBaseURL];
    [self.httpClient postRequestToUrlString:urlString
                                   withVars:self.searchQuery.dictionary
                                 needsLogin:NO
                          completionHandler:^(NSError *error, NSDictionary *data) {
                              NSMutableArray *messages;

                              if (!error) {
                                  messages = [NSMutableArray array];
                                  for (NSDictionary *json in data) {
                                      MCLMessage *message = [MCLMessage messageFromSearchResultJSON:json];
                                      if (message) {
                                          [messages addObject:message];
                                      }
                                  }
                              }

                              if (completionHandler) {
                                  completionHandler(error, messages);
                              }
                          }];
}

@end

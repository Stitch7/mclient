//
//  MCLSearchThreadsRequest.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLSearchThreadsRequest.h"

#import "MCLHTTPClient.h"
#import "MCLBoard.h"

@interface MCLSearchThreadsRequest ()

@property (strong, nonatomic) MCLBoard *board;
@property (strong, nonatomic) NSString *phrase;

@end

@implementation MCLSearchThreadsRequest

@synthesize httpClient;

#pragma mark - Initializers

- (instancetype)initWithClient:(id <MCLHTTPClient>)httpClient board:(MCLBoard *)board andPhrase:(NSString *)phrase
{
    self = [super init];
    if (!self) return nil;

    self.httpClient = httpClient;
    self.board = board;
    self.phrase = phrase;

    return self;
}

#pragma mark - MCLRequest

- (void)loadWithCompletionHandler:(void (^)(NSError*, NSArray*))completionHandler
{
    NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/search-threads", kMServiceBaseURL, self.board.boardId];
    [self.httpClient postRequestToUrlString:urlString
                                   withVars:@{@"phrase":self.phrase}
                                 needsLogin:YES
                          completionHandler:^(NSError *error, NSDictionary *json) {
                              NSMutableArray *data = [NSMutableArray new];
                              if (json) {
                                  [data addObject:json];
                              }
                              completionHandler(error, data);
                          }];
}

@end

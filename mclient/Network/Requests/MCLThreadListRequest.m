//
//  MCLThreadListRequest.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLThreadListRequest.h"

#import "MCLHTTPClient.h"
#import "MCLLogin.h"
#import "MCLBoard.h"
#import "MCLThread.h"

@interface MCLThreadListRequest ()

@property (strong, nonatomic) MCLBoard *board;
@property (strong, nonatomic) MCLLogin *login;

@end

@implementation MCLThreadListRequest

@synthesize httpClient;

#pragma mark - Initializers

- (instancetype)initWithClient:(id <MCLHTTPClient>)httpClient board:(MCLBoard *)board login:(MCLLogin *)login
{
    self = [super init];
    if (!self) return nil;

    self.httpClient = httpClient;
    self.board = board;
    self.login = login;

    return self;
}

#pragma mark - MCLRequest

- (void)loadWithCompletionHandler:(void (^)(NSError*, NSArray*))completionHandler
{
    NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/threads", kMServiceBaseURL, self.board.boardId];
    [self.httpClient getRequestToUrlString:urlString
                                needsLogin:self.login.valid
                         completionHandler:^(NSError *error, NSDictionary *json) {
                             NSMutableArray *favorites = [NSMutableArray array];
                             for (NSDictionary *jsonEntry in json) {
                                 MCLThread *thread = [MCLThread threadFromJSON:jsonEntry];
                                 if (thread) {
                                     [favorites addObject:thread];
                                 }
                             }
                             completionHandler(error, favorites);
                         }];
}

@end

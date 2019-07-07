//
//  MCLThreadListRequest.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLThreadListRequest.h"

#import "MCLHTTPClient.h"
#import "MCLLoginManager.h"
#import "MCLBoard.h"
#import "MCLThread.h"

@interface MCLThreadListRequest ()

@property (strong, nonatomic) MCLBoard *board;
@property (strong, nonatomic) MCLLoginManager *loginManager;

@end

@implementation MCLThreadListRequest

@synthesize httpClient;

#pragma mark - Initializers

- (instancetype)initWithClient:(id <MCLHTTPClient>)httpClient board:(MCLBoard *)board loginManager:(MCLLoginManager *)loginManager
{
    self = [super init];
    if (!self) return nil;

    self.httpClient = httpClient;
    self.board = board;
    self.loginManager = loginManager;

    return self;
}

#pragma mark - MCLRequest

- (void)loadWithCompletionHandler:(void (^)(NSError*, NSArray*))completionHandler
{
    NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/threads", kMServiceBaseURL, self.board.boardId];
    [self.httpClient getRequestToUrlString:urlString
                                needsLogin:self.loginManager.isLoginValid
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

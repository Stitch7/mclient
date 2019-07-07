//
//  MCLMessageListRequest.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLMessageListRequest.h"

#import "MCLHTTPClient.h"
#import "MCLBoard.h"
#import "MCLThread.h"
#import "MCLMessage.h"

@interface MCLMessageListRequest ()

@property (strong, nonatomic) MCLThread *thread;

@end

@implementation MCLMessageListRequest

@synthesize httpClient;

#pragma mark - Initializers

- (instancetype)initWithClient:(id <MCLHTTPClient>)httpClient thread:(MCLThread *)thread
{
    self = [super init];
    if (!self) return nil;

    self.httpClient = httpClient;
    self.thread = thread;

    return self;
}

- (void)loadWithCompletionHandler:(void (^)(NSError*, NSArray*))completionHandler
{
    NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/thread/%@",
                           kMServiceBaseURL, self.thread.board.boardId, self.thread.threadId];
    [self.httpClient getRequestToUrlString:urlString
                                needsLogin:YES
                         completionHandler:^(NSError *error, NSDictionary *data) {
                             NSMutableArray *messages;

                             if (!error) {
                                 messages = [NSMutableArray array];
                                 for (NSDictionary *json in data) {
                                     MCLMessage *message = [MCLMessage messageFromJSON:json];
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

//
//  MCLMessageRequest.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLMessageRequest.h"

#import "MCLHTTPClient.h"
#import "MCLBoard.h"
#import "MCLThread.h"
#import "MCLMessage.h"

@interface MCLMessageRequest ()

@property (strong, nonatomic) MCLMessage *message;

@end

@implementation MCLMessageRequest

@synthesize httpClient;

#pragma mark - Initializers

- (instancetype)initWithClient:(id <MCLHTTPClient>)httpClient message:(MCLMessage *)message
{
    self = [super init];
    if (!self) return nil;

    self.httpClient = httpClient;
    self.message = message;

    return self;
}

#pragma mark - MCLRequest

- (void)loadWithCompletionHandler:(void (^__nonnull)(NSError*, NSArray*))completionHandler
{
    assert(self.message.messageId != nil);
    assert(self.message.board.boardId != nil);
    assert(self.message.thread.threadId != nil);

    NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/thread/%@/message/%@", kMServiceBaseURL,
                           self.message.board.boardId, self.message.thread.threadId, self.message.messageId];
    [self.httpClient getRequestToUrlString:urlString
                                needsLogin:YES
                         completionHandler:^(NSError *error, NSDictionary *json) {
                             NSMutableArray *response = [[NSMutableArray alloc] init];
                             if (!error && json) {
                                 [self.message updateFromMessageTextJSON:json];
                                 [response addObject:json];
                             }
                             completionHandler(error, response);
                         }];
}

@end

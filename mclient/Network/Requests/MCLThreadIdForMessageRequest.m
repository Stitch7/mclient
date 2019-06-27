//
//  MCLThreadIdForMessageRequest.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLThreadIdForMessageRequest.h"

#import "MCLHTTPClient.h"
#import "MCLBoard.h"
#import "MCLMessage.h"

@interface MCLThreadIdForMessageRequest ()

@property (strong, nonatomic) MCLMessage *message;

@end

@implementation MCLThreadIdForMessageRequest

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

- (void)loadWithCompletionHandler:(void (^)(NSError*, NSArray*))completionHandler
{
    if (self.message.board.boardId == nil) {
        completionHandler([[NSError alloc] init], nil);
        return;
    }

    NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/thread-for-message/%@",
                           kMServiceBaseURL, self.message.board.boardId, self.message.messageId];
    [self.httpClient getRequestToUrlString:urlString needsLogin:YES completionHandler:^(NSError *error, NSDictionary *data) {
        NSMutableArray *thread = [NSMutableArray array];
        NSString *threadId = [data objectForKey:@"threadId"];
        if (threadId) {
            [thread addObject:threadId];
        }
        NSString *subject = [data objectForKey:@"subject"];
        if (subject) {
            [thread addObject:subject];
        }

        completionHandler(error, thread);
    }];
}

@end

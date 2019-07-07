//
//  MCLMarkThreadAsReadRequest.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLMarkThreadAsReadRequest.h"

#import "MCLHTTPClient.h"
#import "MCLThread.h"

@interface MCLMarkThreadAsReadRequest ()

@property (strong, nonatomic) MCLThread *thread;

@end

@implementation MCLMarkThreadAsReadRequest

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

#pragma mark - MCLRequest

- (void)loadWithCompletionHandler:(void (^)(NSError*, NSArray*))completionHandler
{
    assert(self.thread.boardId != nil);
    assert(self.thread.threadId != nil);

    NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/thread/%@/mark-as-read",
                           kMServiceBaseURL, self.thread.boardId, self.thread.threadId];
    [self.httpClient getRequestToUrlString:urlString
                                needsLogin:YES
                         completionHandler:^(NSError *error, NSDictionary *json) {
                             completionHandler(error, [NSArray new]);
                         }];
}

@end

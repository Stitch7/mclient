//
//  MCLQuoteMessageRequest.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLQuoteMessageRequest.h"

#import "MCLHTTPClient.h"
#import "MCLBoard.h"
#import "MCLMessage.h"

@interface MCLQuoteMessageRequest ()

@property (strong, nonatomic) MCLMessage *message;

@end

@implementation MCLQuoteMessageRequest

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
    // TODO: - Remove checks if we are really sure ;)
    assert(self.message.boardId != nil);
    assert(self.message.messageId != nil);

    NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/quote/%@",
                           kMServiceBaseURL, self.message.boardId, self.message.messageId];
    [self.httpClient getRequestToUrlString:urlString
                                needsLogin:NO
                         completionHandler:^(NSError *error, NSDictionary *json) {
                             NSMutableArray *data = [NSMutableArray new];
                             [data addObject:json];
                             completionHandler(error, data);
                         }];
}

@end

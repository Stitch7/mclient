//
//  MCLPreviewMessageRequest.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLPreviewMessageRequest.h"

#import "MCLHTTPClient.h"
#import "MCLBoard.h"
#import "MCLMessage.h"

@interface MCLPreviewMessageRequest ()

@property (strong, nonatomic) MCLMessage *message;

@end

@implementation MCLPreviewMessageRequest

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
    assert(self.message.text != nil);

    NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/message/preview", kMServiceBaseURL, self.message.boardId];
    [self.httpClient postRequestToUrlString:urlString
                                   withVars:@{@"text":self.message.text}
                                 needsLogin:NO
                          completionHandler:^(NSError *error, NSDictionary *json) {
                              NSMutableArray *data = [NSMutableArray new];
                              [data addObject:json];
                              completionHandler(error, data);
                          }];
}

@end

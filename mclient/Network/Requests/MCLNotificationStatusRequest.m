//
//  MCLNotificationStatusRequest.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLNotificationStatusRequest.h"

#import "MCLHTTPClient.h"
#import "MCLBoard.h"
#import "MCLMessage.h"

@interface MCLNotificationStatusRequest ()

@property (strong, nonatomic) MCLMessage *message;

@end

@implementation MCLNotificationStatusRequest

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
    assert(self.message.boardId != nil);
    assert(self.message.messageId != nil);

    NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/notification-status/%@",
                           kMServiceBaseURL, self.message.boardId, self.message.messageId];
    [self.httpClient getRequestToUrlString:urlString
                                needsLogin:YES
                         completionHandler:^(NSError *error, NSDictionary *json) {
                             BOOL notificationEnabled = NO;
                             if (!error) {
                                 notificationEnabled = [[json objectForKey:@"notification"] boolValue];
                             }

                             NSMutableArray *data = [NSMutableArray new];
                             [data addObject:[NSNumber numberWithBool:notificationEnabled]];
                             completionHandler(error, data);
                         }];
}

@end

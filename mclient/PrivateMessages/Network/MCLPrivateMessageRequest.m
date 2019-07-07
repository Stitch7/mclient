//
//  MCLPrivateMessageRequest.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLPrivateMessageRequest.h"

#import "MCLHTTPClient.h"
#import "MCLPrivateMessage.h"

@interface MCLPrivateMessageRequest ()

@property (strong, nonatomic) MCLPrivateMessage *privateMessage;

@end

@implementation MCLPrivateMessageRequest

@synthesize httpClient;

#pragma mark - Initializers

- (instancetype)initWithClient:(id <MCLHTTPClient>)httpClient privateMessage:(MCLPrivateMessage *)privateMessage
{
    self = [super init];
    if (!self) return nil;

    self.httpClient = httpClient;
    self.privateMessage = privateMessage;

    return self;
}

#pragma mark - MCLRequest

- (void)loadWithCompletionHandler:(void (^__nonnull)(NSError*, NSArray*))completionHandler
{
    NSString *urlString = [NSString stringWithFormat:@"%@/private-message/%@", kMServiceBaseURL, self.privateMessage.messageId];
    [self.httpClient getRequestToUrlString:urlString
                                needsLogin:YES
                         completionHandler:^(NSError *error, NSDictionary *json) {
                             completionHandler(error, @[json]);
                         }];
}


@end

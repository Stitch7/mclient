//
//  MCLPrivateMessagesListRequest.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLPrivateMessagesListRequest.h"

#import "MCLHTTPClient.h"
#import "MCLPrivateMessage.h"
#import "MCLPrivateMessageConversation.h"

@implementation MCLPrivateMessagesListRequest

@synthesize httpClient;

#pragma mark - Initializers

- (instancetype)initWithClient:(id <MCLHTTPClient>)httpClient
{
    self = [super init];
    if (!self) return nil;

    self.httpClient = httpClient;

    return self;
}

#pragma mark - MCLRequest

- (void)loadWithCompletionHandler:(void (^__nonnull)(NSError*, NSArray*))completionHandler
{
    NSString *urlString = [NSString stringWithFormat:@"%@/private-messages", kMServiceBaseURL];
    [self.httpClient getRequestToUrlString:urlString
                                needsLogin:YES
                         completionHandler:^(NSError *error, NSDictionary *json) {
                             NSMutableArray *conversations = [NSMutableArray array];
                             for (NSDictionary *conversationJson in (NSArray *)json) {
                                 MCLPrivateMessageConversation *conversation = [MCLPrivateMessageConversation conversationFromJSON:conversationJson];
                                 if (conversation) {
                                     [conversations addObject:conversation];
                                 }
                             }
                             completionHandler(error, conversations);
                         }];
}

@end

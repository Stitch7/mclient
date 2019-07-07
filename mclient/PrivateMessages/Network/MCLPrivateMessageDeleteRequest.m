//
//  MCLPrivateMessageDeleteRequest.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLPrivateMessageDeleteRequest.h"

#import "MCLHTTPClient.h"
#import "MCLPrivateMessage.h"

@interface MCLPrivateMessageDeleteRequest ()

@property (strong, nonatomic) MCLPrivateMessage *privateMessage;

@end

@implementation MCLPrivateMessageDeleteRequest

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
    assert(self.privateMessage.messageId != nil);

    NSString *urlString = [NSString stringWithFormat:@"%@/private-message/%@", kMServiceBaseURL, self.privateMessage.messageId];
    [self.httpClient deleteRequestToUrlString:urlString
                                     withVars:nil
                                   needsLogin:YES
                            completionHandler:^(NSError *error, NSDictionary *json) {
                                completionHandler(error, nil);
                            }];
}

@end

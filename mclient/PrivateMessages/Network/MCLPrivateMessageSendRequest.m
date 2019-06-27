//
//  MCLPrivateMessageSendRequest.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLPrivateMessageSendRequest.h"

#import "MCLHTTPClient.h"
#import "MCLPrivateMessage.h"

@interface MCLPrivateMessageSendRequest ()

@property (strong, nonatomic) MCLPrivateMessage *privateMessage;

@end

@implementation MCLPrivateMessageSendRequest

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
    NSString *urlString = [NSString stringWithFormat:@"%@/private-message", kMServiceBaseURL];
    NSDictionary *vars = @{@"subject":@"asd",
                           @"text":self.privateMessage.text};
    [self.httpClient postRequestToUrlString:urlString
                                   withVars:vars
                                 needsLogin:YES
                          completionHandler:^(NSError *error, NSDictionary *json) {
                              completionHandler(error, nil);
                          }];
}

@end

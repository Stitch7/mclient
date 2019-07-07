//
//  MCLSendMessageRequest.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLSendMessageRequest.h"
#import "MCLHTTPClient.h"
#import "MCLMessage.h"
#import "MCLThread.h"

@interface MCLSendMessageRequest ()

@property (strong, nonatomic) MCLMessage *message;

@end

@implementation MCLSendMessageRequest

@synthesize httpClient;

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
    void (^completion)(NSError *error, NSDictionary *json) = ^(NSError *error, NSDictionary *json) {
        NSMutableArray *data = [NSMutableArray new];
        if (json) {
            [data addObject:json];
        }
        completionHandler(error, data);
    };

    switch (self.message.type) {
        case kMCLComposeTypeThread: {
            NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/message", kMServiceBaseURL, self.message.boardId];
            NSDictionary *vars = @{@"subject":self.message.subject,
                                   @"text":self.message.text,
                                   @"notification":[NSString stringWithFormat:@"%d", NO]};
            [self.httpClient postRequestToUrlString:urlString
                                           withVars:vars
                                         needsLogin:YES
                                  completionHandler:completion];
            break;
        }
        case kMCLComposeTypeReply: {
            NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/message/%@",
                                   kMServiceBaseURL, self.message.boardId, self.message.messageId];
            NSDictionary *vars = @{@"threadId":[self.message.thread.threadId stringValue],
                                   @"subject":self.message.subject,
                                   @"text":self.message.text,
                                   @"notification":[NSString stringWithFormat:@"%d", NO]};
            [self.httpClient postRequestToUrlString:urlString
                                               withVars:vars
                                             needsLogin:YES
                                      completionHandler:completion];
            break;
        }
        case kMCLComposeTypeEdit: {
            NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/message/%@",
                                   kMServiceBaseURL, self.message.boardId, self.message.messageId];
            NSDictionary *vars = @{@"threadId":[self.message.thread.threadId stringValue],
                                   @"subject":self.message.subject,
                                   @"text":self.message.text};
            [self.httpClient putRequestToUrlString:urlString
                                              withVars:vars
                                            needsLogin:YES
                                     completionHandler:completion];
            break;
        }
        default:

            break;
    }
}

@end

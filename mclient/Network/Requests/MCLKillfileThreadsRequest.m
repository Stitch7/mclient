//
//  MCLKillfileThreadsRequest.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLKillfileThreadsRequest.h"

#import "MCLHTTPClient.h"
#import "MCLThread.h"

@implementation MCLKillfileThreadsRequest

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
    NSString *urlString = [NSString stringWithFormat:@"%@/killfile/threads", kMServiceBaseURL];
    [self.httpClient getRequestToUrlString:urlString
                                needsLogin:YES
                         completionHandler:^(NSError *error, NSDictionary *json) {
                             NSMutableArray *favorites = [NSMutableArray array];
                             for (NSDictionary *jsonEntry in json) {
                                 MCLThread *thread = [MCLThread threadFromJSON:jsonEntry];
                                 if (thread) {
                                     [favorites addObject:thread];
                                 }
                             }

                             completionHandler(error, favorites);
                         }];
}

@end

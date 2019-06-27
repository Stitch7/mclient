//
//  MCLFavoriteThreadToggleRequest.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLFavoriteThreadToggleRequest.h"

#import "MCLHTTPClient.h"
#import "MCLThread.h"


@interface MCLFavoriteThreadToggleRequest ()

@property (strong, nonatomic) MCLThread *thread;

@end

@implementation MCLFavoriteThreadToggleRequest

@synthesize httpClient;

#pragma mark - Initializers

- (instancetype)initWithClient:(id <MCLHTTPClient>)httpClient thread:(MCLThread *)thread
{
    self = [super init];
    if (!self) return nil;

    self.httpClient = httpClient;
    self.thread = thread;
    self.forceRemove = NO;

    return self;
}

#pragma mark - MCLRequest

- (void)loadWithCompletionHandler:(void (^__nonnull)(NSError*, NSArray*))completionHandler
{
    NSString *urlString = [NSString stringWithFormat:@"%@/favorites/%@", kMServiceBaseURL, self.thread.threadId];
    void (^block)(NSError*,  NSDictionary*) = ^(NSError *error, NSDictionary *json) {
        NSMutableArray *result = [NSMutableArray array];
        completionHandler(error, result);
    };

    if (self.thread.isFavorite && !self.forceRemove) {
        [self.httpClient postRequestToUrlString:urlString
                                       withVars:nil
                                     needsLogin:YES
                              completionHandler:block];
    } else {
        [self.httpClient deleteRequestToUrlString:urlString
                                         withVars:nil
                                       needsLogin:YES
                                completionHandler:block];
    }
}

@end

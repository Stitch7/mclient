//
//  MCLBoardListRequest.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLBoardListRequest.h"

#import "MCLHTTPClient.h"
#import "MCLBoard.h"

@implementation MCLBoardListRequest

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
    NSString *urlString = [NSString stringWithFormat:@"%@/boards", kMServiceBaseURL];
    [self.httpClient getRequestToUrlString:urlString
                                needsLogin:NO
                         completionHandler:^(NSError *error, NSDictionary *json) {
                             NSMutableArray *boards = [NSMutableArray array];
                             for (NSDictionary *jsonEntry in json) {
                                 MCLBoard *board = [MCLBoard boardFromJSON:jsonEntry];
                                 if (board) {
                                     [boards addObject:board];
                                 }
                             }
                             completionHandler(error, boards);
                         }];
}

@end

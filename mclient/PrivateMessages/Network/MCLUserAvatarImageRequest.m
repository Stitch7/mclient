//
//  MCLUserAvatarImageRequest.m
//  mclient
//
//  Created by Christopher Reitz on 28.02.19.
//  Copyright © 2019 Christopher Reitz. All rights reserved.
//

#import "MCLUserAvatarImageRequest.h"

#import "MCLHTTPClient.h"


@interface MCLUserAvatarImageRequest ()

@property (strong, nonatomic) NSString *username;

@end

@implementation MCLUserAvatarImageRequest

@synthesize httpClient;

#pragma mark - Initializers

- (instancetype)initWithClient:(id <MCLHTTPClient>)httpClient username:(NSString *)username
{
    self = [super init];
    if (!self) return nil;

    self.httpClient = httpClient;
    self.username = username;

    return self;
}

#pragma mark - MCLRequest

- (void)loadWithCompletionHandler:(void (^__nonnull)(NSError*, NSArray*))completionHandler
{
    NSString *urlString = [NSString stringWithFormat:@"%@/user/%@/avatar.png", kMServiceBaseURL, self.username];
    [self.httpClient getRequestToUrlString:urlString
                                needsLogin:NO
                         completionHandler:^(NSError *error, NSDictionary *json) {
                             completionHandler(error, nil);
                         }];
}


@end

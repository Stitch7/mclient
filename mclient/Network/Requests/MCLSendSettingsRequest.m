//
//  MCLSendSettingsRequest.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLSendSettingsRequest.h"

#import "MCLHTTPClient.h"
#import "MCLSettings.h"

@interface MCLSendSettingsRequest ()

@property (strong, nonatomic) NSString *uuid;
@property (strong, nonatomic) MCLSettings *settings;

@end

@implementation MCLSendSettingsRequest

@synthesize httpClient;

#pragma mark - Initializers

- (instancetype)initWithClient:(id <MCLHTTPClient>)httpClient uuid:(NSString *)uuid settings:(MCLSettings *)settings
{
    self = [super init];
    if (!self) return nil;

    self.httpClient = httpClient;
    self.uuid = uuid;
    self.settings = settings;

    return self;
}

#pragma mark - MCLRequest

- (void)loadWithCompletionHandler:(void (^)(NSError*, NSArray*))completionHandler
{
    NSString *urlString = [NSString stringWithFormat:@"%@/settings/%@", kMServiceBaseURL, self.uuid];
    [self.httpClient postRequestToUrlString:urlString
                                   withJSON:self.settings.dictionaryWithAllSettings
                                 needsLogin:YES
                          completionHandler:^(NSError *error, NSDictionary *data) {
                              if (completionHandler) {
                                  completionHandler(error, @[]);
                              }
                          }];
}

@end

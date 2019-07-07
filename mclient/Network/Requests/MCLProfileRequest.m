//
//  MCLProfileRequest.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLProfileRequest.h"

#import "MCLHTTPClient.h"
#import "MCLUser.h"


@interface MCLProfileRequest ()

@property (strong, nonatomic) MCLUser *user;
@property (strong, nonatomic) NSArray *profileKeys;
@property (strong, nonatomic) NSMutableDictionary *profileData;
@property (strong, nonatomic) UIImage *profileImage;

@end

@implementation MCLProfileRequest

@synthesize httpClient;
@synthesize profileKeys = _profileKeys;

- (NSArray *)profileKeys
{
    if (!_profileKeys) {
        _profileKeys = @[@"picture",
                         @"firstname",
                         @"lastname",
                         @"domicile",
                         @"accountNo",
                         @"registrationDate",
                         @"icq",
                         @"homepage",
                         @"firstGame",
                         @"allTimeClassics",
                         @"favoriteGenres",
                         @"currentSystems",
                         @"hobbies",
                         @"xboxLiveGamertag",
                         @"psnId",
                         @"nintendoFriendcode",
                         @"lastUpdate"];
    }

    return _profileKeys;
}

#pragma mark - Initializers

- (instancetype)initWithClient:(id <MCLHTTPClient>)httpClient user:(MCLUser *)user
{
    self = [super init];
    if (!self) return nil;

    self.httpClient = httpClient;
    self.user = user;

    return self;
}

#pragma mark - MCLRequest

- (void)loadWithCompletionHandler:(void (^__nonnull)(NSError*, NSArray*))completionHandler
{
    NSString *urlString;
    if (self.user.userId) {
        urlString = [NSString stringWithFormat:@"%@/user/%@", kMServiceBaseURL, self.user.userId];
    } else {
        urlString = [NSString stringWithFormat:@"%@/username/%@", kMServiceBaseURL, self.user.username];
    }
    [self.httpClient getRequestToUrlString:urlString
                                needsLogin:YES
                         completionHandler:^(NSError *error, NSDictionary *json) {
                             self.profileData = [NSMutableDictionary dictionary];
                             for (NSString *key in self.profileKeys) {
                                 NSString *value = [json objectForKey:key];
                                 if (value) {
                                     [self.profileData setObject:value forKey:key];
                                 }
                             }

                             NSDateFormatter *dateFormatterForInput = [[NSDateFormatter alloc] init];
                             NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
                             [dateFormatterForInput setLocale:enUSPOSIXLocale];
                             [dateFormatterForInput setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];

                             NSDateFormatter *dateFormatterForOutput = [[NSDateFormatter alloc] init];
                             [dateFormatterForOutput setDoesRelativeDateFormatting:YES];
                             [dateFormatterForOutput setDateStyle:NSDateFormatterShortStyle];
                             [dateFormatterForOutput setTimeStyle:NSDateFormatterShortStyle];

                             NSString *dateString;
                             for (NSString *key in @[@"registrationDate", @"lastUpdate"]) {
                                 dateString = [json objectForKey:key];
                                 if ([dateString length] > 0) {
                                     dateString = [dateFormatterForOutput stringFromDate:[dateFormatterForInput dateFromString:dateString]];
                                     [self.profileData setObject:dateString forKey:key];
                                 }
                             }

                             completionHandler(error, @[self.profileKeys, self.profileData]);
                         }];
}

@end

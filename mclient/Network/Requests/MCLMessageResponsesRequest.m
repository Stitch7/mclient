//
//  MCLMessageResponsesRequest.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLMessageResponsesRequest.h"

#import "MCLDependencyBag.h"
#import "MCLHTTPClient.h"
#import "MCLLoginManager.h"
#import "MCLResponse.h"

NSString * const MCLUnreadResponsesFoundNotification = @"MCLUnreadResponsesFoundNotification";

@interface MCLMessageResponsesRequest ()

@property (strong, nonatomic) id <MCLDependencyBag> bag;

@end

@implementation MCLMessageResponsesRequest

@synthesize httpClient;

#pragma mark - Initializers

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag
{
    self = [super init];
    if (!self) return nil;

    self.bag = bag;

    return self;
}

#pragma mark - Helpers

- (MCLResponseContainer *)fetchedData:(NSDictionary *)data
{
    NSMutableArray *sectionKeys = [NSMutableArray array];
    NSMutableDictionary *sectionTitles = [NSMutableDictionary dictionary];
    NSMutableDictionary *responses = [NSMutableDictionary dictionary];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];

    NSDateFormatter *dateKeyFormatter = [[NSDateFormatter alloc] init];
    [dateKeyFormatter setDateFormat: @"yyyy-MM-dd"];

    NSDateFormatter *dateStrFormatter = [[NSDateFormatter alloc] init];
    [dateStrFormatter setDoesRelativeDateFormatting:YES];
    [dateStrFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateStrFormatter setTimeStyle:NSDateFormatterNoStyle];

    for (id object in data) {
        NSNumber *boardId = [object objectForKey:@"boardId"];
        NSNumber *threadId = [object objectForKey:@"threadId"];
        NSString *threadSubject = [object objectForKey:@"threadSubject"];
        NSNumber *messageId = [object objectForKey:@"messageId"];
        id isReadOpt = [object objectForKey:@"isRead"];
        BOOL isRead = (isReadOpt != (id)[NSNull null] && isReadOpt != nil) ? [isReadOpt boolValue] : YES;
        NSString *username = [object objectForKey:@"username"];
        NSString *subject = [object objectForKey:@"subject"];
        NSDate *date = [dateFormatter dateFromString:[object objectForKey:@"date"]];

        NSString *sectionKey = [[dateKeyFormatter stringFromDate:date] stringByAppendingString:threadSubject];

        NSMutableArray *responsesWithKey = [NSMutableArray array];
        if (![sectionKeys containsObject:sectionKey]) {
            [sectionKeys addObject:sectionKey];
            NSString *dateStr = [dateStrFormatter stringFromDate:date];
            NSDictionary *sectionTitle = @{@"date": dateStr, @"subject": threadSubject};
            [sectionTitles setObject:sectionTitle forKey:sectionKey];
        }
        else {
            responsesWithKey = [responses objectForKey:sectionKey];
        }

        MCLResponse *response = [MCLResponse responseWithBoardId:boardId
                                                        threadId:threadId
                                                   threadSubject:threadSubject
                                                       messageId:messageId
                                                         subject:subject
                                                        username:username
                                                            date:date
                                                            read:isRead];
        [responsesWithKey addObject:response];



        NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
        NSMutableArray *sortedResponsesWithKey = [NSMutableArray arrayWithArray:[responsesWithKey sortedArrayUsingDescriptors:@[descriptor]]];

        [responses setObject:sortedResponsesWithKey forKey:sectionKey];
    }

    NSArray *sortedSections = [sectionKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    sectionKeys = [NSMutableArray arrayWithArray:[[sortedSections reverseObjectEnumerator] allObjects]];

    return [[MCLResponseContainer alloc] initWithResponses:responses
                                               sectionKeys:sectionKeys
                                                 andTitles:sectionTitles];
}

#pragma mark - Public Methods -

- (void)loadResponsesWithCompletion:(void (^)(NSError *error, MCLResponseContainer *responseContainer))completion
{
    NSString *username = self.bag.loginManager.username;
    NSString *urlString = [NSString stringWithFormat:@"%@/user/%@/responses", kMServiceBaseURL, username];
    [self.bag.httpClient getRequestToUrlString:urlString
                                needsLogin:YES
                         completionHandler:^(NSError *error, NSDictionary *json) {
                             if (error) {
                                 if (completion) {
                                     completion(error, nil);
                                 }
                                 return;
                             }

                             MCLResponseContainer *responseContainer = [self fetchedData:json];
                             NSInteger numberOfUnreadResponses = [responseContainer numberOfUnreadResponses];
                             self.bag.application.applicationIconBadgeNumber = numberOfUnreadResponses;
                             NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                                       responseContainer.responses, @"responses",
                                                       [NSNumber numberWithInteger:numberOfUnreadResponses], @"numberOfUnreadResponses", nil];
                             [[NSNotificationCenter defaultCenter] postNotificationName:MCLUnreadResponsesFoundNotification
                                                                                 object:self
                                                                               userInfo:userInfo];

                             if (completion) {
                                 completion(nil, responseContainer);
                             }
                         }];
}

- (void)loadUnreadResponsesWithCompletion:(void (^)(NSError *error, NSArray *unreadResponses))completion
{
    [self loadResponsesWithCompletion:^(NSError *error, MCLResponseContainer *responseContainer) {
        if (error) {
            completion(error, nil);
            return;
        }

        completion(error, [responseContainer unreadResponses]);
    }];
}

- (void)loadWithCompletionHandler:(void (^)(NSError *, NSArray *))completion
{
    NSString *username = [self.bag.loginManager username];
    NSString *urlString = [NSString stringWithFormat:@"%@/user/%@/responses", kMServiceBaseURL, username];
    [self.bag.httpClient getRequestToUrlString:urlString
                                    needsLogin:YES
                             completionHandler:^(NSError *error, NSDictionary *json) {
                                 if (error) {
                                     if (completion) {
                                         completion(error, nil);
                                     }
                                     return;
                                 }

                                 MCLResponseContainer *responseContainer = [self fetchedData:json];
                                 NSArray *responses = [NSArray arrayWithObject:responseContainer];
                                 if (completion) {
                                     completion(nil, responses);
                                 }
                             }];
}

@end

//
//  MCLMessageResponsesClient.m
//  mclient
//
//  Created by Christopher Reitz on 28/02/2017.
//  Copyright © 2017 Christopher Reitz. All rights reserved.
//

#import "MCLMessageResponsesClient.h"

#import "KeychainItemWrapper.h"
#import "MCLMServiceConnector.h"
#import "MCLResponse.h"

@implementation MCLMessageResponsesClient

- (void)loadData
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *mServiceError;
        NSDictionary *data = [[MCLMServiceConnector sharedConnector] responsesForUsername:[self usernameFromKeychain]
                                                                                    error:&mServiceError];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

        if (mServiceError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate messageResponsesClient:self failedWithError:mServiceError];
            });
        }
        else {
            [self fetchedData:data];
        }
    });
}

- (NSString *)usernameFromKeychain
{
    NSString *keychainIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:keychainIdentifier
                                                                            accessGroup:nil];
    return [keychainItem objectForKey:(__bridge id)(kSecAttrAccount)];
}

- (void)fetchedData:(NSDictionary *)data
{
    int foundUnreadResponses = 0;
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

        if (!isRead) {
            foundUnreadResponses++;
        }

        NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
        NSMutableArray *sortedResponsesWithKey = [NSMutableArray arrayWithArray:[responsesWithKey sortedArrayUsingDescriptors:@[descriptor]]];

        [responses setObject:sortedResponsesWithKey forKey:sectionKey];
    }

    NSArray *sortedSections = [sectionKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    sectionKeys = [NSMutableArray arrayWithArray:[[sortedSections reverseObjectEnumerator] allObjects]];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate messageResponsesClient:self fetchedData:responses sectionKeys:sectionKeys sectionTitles:sectionTitles];
        [self.delegate messageResponsesClient:self foundUnreadResponses:[NSNumber numberWithInt:foundUnreadResponses]];
    });
}

@end

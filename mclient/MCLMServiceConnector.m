//
//  MCLMServiceConnector.m
//  mclient
//
//  Created by Christopher Reitz on 02.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLMServiceConnector.h"

#import "constants.h"
#import "Reachability.h"

@implementation MCLMServiceConnector

#pragma mark - Accessors
@synthesize errorMessages = _errorMessages;

- (NSDictionary *)errorMessages
{
    if ( ! _errorMessages) {
        _errorMessages = @{@(-2):@"No Internet Connection",
                           @(-1):@"Connection to M!service failed",
                           @(0): @"Action could not be executed",               // :unknown
                           @(1): @"Man!ac Forum Server down?",                  // :connection
                           @(2): @"Action could not be executed",               // :permission
                           @(3): @"Please verify your login data in settings",  // :login
                           @(4): @"Action could not be executed",               // :boardId
                           @(5): @"Action could not be executed",               // :messageId
                           @(6): @"Please fill out the subject field",          // :subject
                           @(7): @"Editing this message is no longer allowed"}; // :answerExists
    }

    return _errorMessages;
}


#pragma mark Singleton Methods

+ (id)sharedConnector
{
    static MCLMServiceConnector *sharedMServiceConnector = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMServiceConnector = [[self alloc] init];
    });

    return sharedMServiceConnector;
}

#pragma mark Public Methods

- (NSDictionary *)boards:(NSError **)errorPtr
{
    NSString *urlString = [NSString stringWithFormat:@"%@/boards", kMServiceBaseURL];
    return [self getRequestToUrlString:urlString error:errorPtr];
}

- (NSDictionary *)threadsFromBoardId:(NSNumber *)inBoardId
                               error:(NSError **)errorPtr
{
    NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/threads", kMServiceBaseURL, inBoardId];
    return [self getRequestToUrlString:urlString error:errorPtr];
}

- (NSDictionary *)threadWithId:(NSNumber *)inThreadId
                   fromBoardId:(NSNumber *)inBoardId
                         error:(NSError **)errorPtr
{
    NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/thread/%@", kMServiceBaseURL, inBoardId, inThreadId];
    return [self getRequestToUrlString:urlString error:errorPtr];
}

- (NSDictionary *)messageWithId:(NSNumber *)inMessageId
                    fromBoardId:(NSNumber *)inBoardId
                          error:(NSError **)errorPtr
{
    NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/message/%@", kMServiceBaseURL, inBoardId, inMessageId];
    return [self getRequestToUrlString:urlString error:errorPtr];
}

- (NSDictionary *)quoteMessageWithId:(NSNumber *)inMessageId
                         fromBoardId:(NSNumber *)inBoardId
                               error:(NSError **)errorPtr
{
    NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/quote/%@", kMServiceBaseURL, inBoardId, inMessageId];
    return [self getRequestToUrlString:urlString error:errorPtr];
}

- (NSDictionary *)userWithId:(NSNumber *)inUserId
                       error:(NSError **)errorPtr
{
    NSString *urlString = [NSString stringWithFormat:@"%@/user/%@", kMServiceBaseURL, inUserId];
    return [self getRequestToUrlString:urlString error:errorPtr];
}


- (BOOL)testLoginWIthUsername:(NSString *)inUsername
                     password:(NSString *)inPassword
                        error:(NSError **)errorPtr
{
    BOOL success = NO;

    if (inUsername.length > 0 && inPassword.length > 0) {
        NSString *urlString = [NSString stringWithFormat:@"%@/test-login", kMServiceBaseURL];

        NSDictionary *vars = @{@"username":[self percentEscapeString:inUsername],
                               @"password":[self percentEscapeString:inPassword]};

        NSDictionary *data = [self postRequestToUrlString:urlString withVars:vars error:errorPtr];

        if ( ! *errorPtr) {
            success = [[data objectForKey:@"success"] boolValue];
        }
    }

    return success;
}

- (BOOL)notificationStatusForMessageId:(NSNumber *)inMessageId
                                    boardId:(NSNumber *)inBoardId
                                   username:(NSString *)inUsername
                                   password:(NSString *)inPassword
                                      error:(NSError **)errorPtr
{
    BOOL notificationEnabled = NO;
    
    NSDictionary *vars = @{@"username":[self percentEscapeString:inUsername],
                           @"password":[self percentEscapeString:inPassword]};
    
    
    NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/notification-status/%@", kMServiceBaseURL, inBoardId, inMessageId];

    NSDictionary *data = [self postRequestToUrlString:urlString withVars:vars error:errorPtr];

    if ( ! *errorPtr) {
        notificationEnabled = [[data objectForKey:@"notificationEnabled"] boolValue];
    }
    
    return notificationEnabled;
}

- (BOOL)notificationForMessageId:(NSNumber *)inMessageId
                         boardId:(NSNumber *)inBoardId
                        username:(NSString *)inUsername
                        password:(NSString *)inPassword
                           error:(NSError **)errorPtr
{
    BOOL success = NO;

    NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/notification/%@", kMServiceBaseURL, inBoardId, inMessageId];

    NSDictionary *vars = @{@"username":[self percentEscapeString:inUsername],
                           @"password":[self percentEscapeString:inPassword]};

    NSDictionary *data = [self postRequestToUrlString:urlString withVars:vars error:errorPtr];

    if ( ! *errorPtr) {
        success = [[data objectForKey:@"success"] boolValue];
    }

    return success;
}

- (NSDictionary *)messagePreviewForBoardId:(NSNumber *)inBoardId
                                      text:(NSString *)inText
                                     error:(NSError **)errorPtr
{
    NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/message/preview", kMServiceBaseURL, inBoardId];

    NSDictionary *vars = @{@"text":[self percentEscapeString:inText]};

    return [self postRequestToUrlString:urlString withVars:vars error:errorPtr];
}


- (BOOL)postThreadToBoardId:(NSNumber *)inBoardId
                    subject:(NSString *)inSubject
                       text:(NSString *)inText
                   username:(NSString *)inUsername
                   password:(NSString *)inPassword
               notification:(BOOL)inNotification
                      error:(NSError **)errorPtr
{
    BOOL success = NO;

    NSDictionary *vars = @{@"boardId":inBoardId,
                           @"messageId":@"",
                           @"subject":[self percentEscapeString:inSubject],
                           @"text":[self percentEscapeString:inText],
                           @"username":[self percentEscapeString:inUsername],
                           @"password":[self percentEscapeString:inPassword],
                           @"notification":[NSNumber numberWithBool:inNotification]};
    
    NSDictionary *data = [self postRequestToUrlString:@"post" withVars:vars error:errorPtr];

    if ( ! *errorPtr) {
        success = [[data objectForKey:@"success"] boolValue];
    }

    return success;
}

- (BOOL)postReplyToMessageId:(NSNumber *)inMessageId
                     boardId:(NSNumber *)inBoardId
                     subject:(NSString *)inSubject
                        text:(NSString *)inText
                    username:(NSString *)inUsername
                    password:(NSString *)inPassword
                notification:(BOOL)inNotification
                       error:(NSError **)errorPtr
{
    BOOL success = NO;

    NSDictionary *vars = @{@"subject":[self percentEscapeString:inSubject],
                           @"text":[self percentEscapeString:inText],
                           @"username":[self percentEscapeString:inUsername],
                           @"password":[self percentEscapeString:inPassword],
                           @"notification":[NSNumber numberWithBool:inNotification]};

    NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/message/%@", kMServiceBaseURL, inBoardId, inMessageId];

    NSDictionary *data = [self postRequestToUrlString:urlString withVars:vars error:errorPtr];

    if ( ! *errorPtr) {
        success = [[data objectForKey:@"success"] boolValue];
    }

    return success;
}

- (BOOL)postEditToMessageId:(NSNumber *)inMessageId
                    boardId:(NSNumber *)inBoardId
                    subject:(NSString *)inSubject
                       text:(NSString *)inText
                   username:(NSString *)inUsername
                   password:(NSString *)inPassword
                      error:(NSError **)errorPtr
{
    BOOL success = NO;

    NSDictionary *vars = @{@"subject":[self percentEscapeString:inSubject],
                           @"text":[self percentEscapeString:inText],
                           @"username":[self percentEscapeString:inUsername],
                           @"password":[self percentEscapeString:inPassword]};
    
    NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/message/%@", kMServiceBaseURL, inBoardId, inMessageId];
    NSDictionary *data = [self putRequestToUrlString:urlString withVars:vars error:errorPtr];

    if ( ! *errorPtr) {
        success = [[data objectForKey:@"success"] boolValue];
    }

    return success;
}

- (NSDictionary *)searchThreadsOnBoard:(NSNumber *)inBoardId
               withPhrase:(NSString *)inPhrase
                    error:(NSError **)errorPtr
{
    NSDictionary *vars = @{@"phrase":[self percentEscapeString:inPhrase]};
    
    NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/search-threads", kMServiceBaseURL, inBoardId];

    return [self postRequestToUrlString:urlString withVars:vars error:errorPtr];
}

- (NSDictionary *)getRequestToUrlString:(NSString *)urlString error:(NSError **)errorPtr
{
    NSDictionary *reply = nil;
    NSNumber *errorCode = nil;

    if ([self noInternetConnectionAvailable]) {
        errorCode = @(-2);
    } else {
        NSData *responseData = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
        if (responseData) {
            NSError *jsonError;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&jsonError];

            if ([json objectForKey:@"error"] == [NSNull null]) {
                reply = [json objectForKey:@"data"];
            } else {
                NSDictionary *error = [json objectForKey:@"error"];
                errorCode = [error objectForKey:@"code"];
            }
        } else {
            errorCode = @(-1);
        }
    }

    if (errorCode) {
        *errorPtr = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier]
                                        code:[errorCode integerValue]
                                    userInfo:@{NSLocalizedDescriptionKey:[self.errorMessages objectForKey:errorCode]}];
    }

    return reply;
}

- (NSDictionary *)postRequestToUrlString:(NSString *)urlString withVars:(NSDictionary *)vars error:(NSError **)errorPtr
{
    return [self requestWithHTTPMethod:@"POST" toUrlString:urlString withVars:vars error:errorPtr];
}

- (NSDictionary *)putRequestToUrlString:(NSString *)urlString withVars:(NSDictionary *)vars error:(NSError **)errorPtr
{
    return [self requestWithHTTPMethod:@"PUT" toUrlString:urlString withVars:vars error:errorPtr];
}

- (NSDictionary *)requestWithHTTPMethod:(NSString *)httpMethod toUrlString:(NSString *)urlString withVars:(NSDictionary *)vars error:(NSError **)errorPtr
{
    NSDictionary *reply = nil;
    NSNumber *errorCode = nil;

    if ([self noInternetConnectionAvailable]) {
        errorCode = @(-2);
    } else {
        NSURL *url = [NSURL URLWithString:urlString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        
        NSString *requestFields = @"";
        for (id key in vars) {
            requestFields = [requestFields stringByAppendingFormat:@"%@=%@&", key, [vars objectForKey:key]];
        }

        NSData *requestData = [requestFields dataUsingEncoding:NSUTF8StringEncoding];
        request.HTTPBody = requestData;
        request.HTTPMethod = httpMethod;
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        
        NSHTTPURLResponse *response = nil;
        NSError *responseError = nil;
        NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&responseError];

        if (responseError) {
            errorCode = @(-1);
        } else {
            switch (response.statusCode) {
                case 500:
                    errorCode = @(0);
                    break;

                case 200: {
                    NSError *jsonError;
                    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&jsonError];

                    if ([json objectForKey:@"error"] == [NSNull null]) {
                        reply = [json objectForKey:@"data"];
                    } else {
                        NSDictionary *error = [json objectForKey:@"error"];
                        errorCode = [error objectForKey:@"code"];
                    }
                } break;
            }
        }
    }

    if (errorCode) {
        *errorPtr = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier]
                                        code:[errorCode integerValue]
                                    userInfo:@{NSLocalizedDescriptionKey:[self.errorMessages objectForKey:errorCode]}];
    }

    return reply;
}

- (BOOL)noInternetConnectionAvailable
{
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];

    return networkStatus == NotReachable;
}

- (NSString *)percentEscapeString:(NSString *)string
{
    NSString *result = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                 (CFStringRef)string,
                                                                                 (CFStringRef)@" ",
                                                                                 (CFStringRef)@":/?@!$&'()*+,;=",
                                                                                 kCFStringEncodingUTF8));
    return [result stringByReplacingOccurrencesOfString:@" " withString:@"+"];
}

@end

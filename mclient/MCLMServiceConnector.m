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

- (void)testLoginWithUsername:(NSString *)inUsername
                     password:(NSString *)inPassword
                        error:(NSError **)errorPtr
{
    NSString *urlString = [NSString stringWithFormat:@"%@/test-login", kMServiceBaseURL];

    NSDictionary *loginData = @{@"username":inUsername,
                                @"password":inPassword};

    [self getRequestToUrlString:urlString login:loginData error:errorPtr];
}

- (NSDictionary *)boards:(NSError **)errorPtr
{
    NSString *urlString = [NSString stringWithFormat:@"%@/boards", kMServiceBaseURL];
    return [self getRequestToUrlString:urlString login:nil error:errorPtr];
}

- (NSDictionary *)threadsFromBoardId:(NSNumber *)inBoardId
                               error:(NSError **)errorPtr
{
    NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/threads", kMServiceBaseURL, inBoardId];
    return [self getRequestToUrlString:urlString login:nil error:errorPtr];
}

- (NSDictionary *)threadWithId:(NSNumber *)inThreadId
                   fromBoardId:(NSNumber *)inBoardId
                         error:(NSError **)errorPtr
{
    NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/thread/%@", kMServiceBaseURL, inBoardId, inThreadId];
    return [self getRequestToUrlString:urlString login:nil error:errorPtr];
}

- (NSDictionary *)messageWithId:(NSNumber *)inMessageId
                    fromBoardId:(NSNumber *)inBoardId
                          login:(NSDictionary *)loginData
                          error:(NSError **)errorPtr
{
    NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/message/%@", kMServiceBaseURL, inBoardId, inMessageId];
    return [self getRequestToUrlString:urlString login:loginData error:errorPtr];
}

- (NSDictionary *)quoteMessageWithId:(NSNumber *)inMessageId
                         fromBoardId:(NSNumber *)inBoardId
                               error:(NSError **)errorPtr
{
    NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/quote/%@", kMServiceBaseURL, inBoardId, inMessageId];
    return [self getRequestToUrlString:urlString login:nil error:errorPtr];
}

- (NSDictionary *)userWithId:(NSNumber *)inUserId
                       error:(NSError **)errorPtr
{
    NSString *urlString = [NSString stringWithFormat:@"%@/user/%@", kMServiceBaseURL, inUserId];
    return [self getRequestToUrlString:urlString login:nil error:errorPtr];
}

- (BOOL)notificationStatusForMessageId:(NSNumber *)inMessageId
                               boardId:(NSNumber *)inBoardId
                              username:(NSString *)inUsername
                              password:(NSString *)inPassword
                                 error:(NSError **)errorPtr
{
    BOOL notificationEnabled = NO;
    
    NSDictionary *loginData = @{@"username":inUsername,
                                @"password":inPassword};
    
    
    NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/notification-status/%@", kMServiceBaseURL, inBoardId, inMessageId];

    NSDictionary *data = [self getRequestToUrlString:urlString login:loginData error:errorPtr];

    if ( ! *errorPtr) {
        notificationEnabled = [[data objectForKey:@"notification"] boolValue];
    }
    
    return notificationEnabled;
}

- (void)notificationForMessageId:(NSNumber *)inMessageId
                         boardId:(NSNumber *)inBoardId
                        username:(NSString *)inUsername
                        password:(NSString *)inPassword
                           error:(NSError **)errorPtr
{
    NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/notification/%@", kMServiceBaseURL, inBoardId, inMessageId];

    NSDictionary *loginData = @{@"username":inUsername,
                                @"password":inPassword};

    [self getRequestToUrlString:urlString login:loginData error:errorPtr];
}

- (NSDictionary *)messagePreviewForBoardId:(NSNumber *)inBoardId
                                      text:(NSString *)inText
                                     error:(NSError **)errorPtr
{
    NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/message/preview", kMServiceBaseURL, inBoardId];

    NSDictionary *vars = @{@"text":inText};

    return [self postRequestToUrlString:urlString withVars:vars login:nil error:errorPtr];
}


- (void)postThreadToBoardId:(NSNumber *)inBoardId
                    subject:(NSString *)inSubject
                       text:(NSString *)inText
                   username:(NSString *)inUsername
                   password:(NSString *)inPassword
               notification:(BOOL)inNotification
                      error:(NSError **)errorPtr
{
    NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/message", kMServiceBaseURL, inBoardId];

    NSDictionary *vars = @{@"subject":inSubject,
                           @"text":inText,
                           @"notification":[NSString stringWithFormat:@"%d", inNotification]};

    NSDictionary *loginData = @{@"username":inUsername,
                                @"password":inPassword};

    [self postRequestToUrlString:urlString withVars:vars login:loginData error:errorPtr];
}

- (void)postReplyToMessageId:(NSNumber *)inMessageId
                     boardId:(NSNumber *)inBoardId
                     threadId:(NSNumber *)inThreadId
                     subject:(NSString *)inSubject
                        text:(NSString *)inText
                    username:(NSString *)inUsername
                    password:(NSString *)inPassword
                notification:(BOOL)inNotification
                       error:(NSError **)errorPtr
{
    NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/message/%@", kMServiceBaseURL, inBoardId, inMessageId];

    NSDictionary *vars = @{@"threadId":[inThreadId stringValue],
                           @"subject":inSubject,
                           @"text":inText,
                           @"notification":[NSString stringWithFormat:@"%d", inNotification]};

    NSDictionary *loginData = @{@"username":inUsername,
                                @"password":inPassword};

    [self postRequestToUrlString:urlString withVars:vars login:loginData error:errorPtr];
}

- (void)postEditToMessageId:(NSNumber *)inMessageId
                    boardId:(NSNumber *)inBoardId
                   threadId:(NSNumber *)inThreadId
                    subject:(NSString *)inSubject
                       text:(NSString *)inText
                   username:(NSString *)inUsername
                   password:(NSString *)inPassword
                      error:(NSError **)errorPtr
{
    NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/message/%@", kMServiceBaseURL, inBoardId, inMessageId];

    NSDictionary *vars = @{@"threadId":[inThreadId stringValue],
                           @"subject":inSubject,
                           @"text":inText};

    NSDictionary *loginData = @{@"username":inUsername,
                                @"password":inPassword};

    [self putRequestToUrlString:urlString withVars:vars login:loginData error:errorPtr];
}

- (NSDictionary *)searchThreadsOnBoard:(NSNumber *)inBoardId
               withPhrase:(NSString *)inPhrase
                    error:(NSError **)errorPtr
{
    NSDictionary *vars = @{@"phrase":inPhrase};
    
    NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/search-threads", kMServiceBaseURL, inBoardId];

    return [self postRequestToUrlString:urlString withVars:vars login:nil error:errorPtr];
}


#pragma mark Private Methods

- (NSDictionary *)getRequestToUrlString:(NSString *)urlString login:(NSDictionary *)loginData error:(NSError **)errorPtr
{
    return [self requestWithHTTPMethod:@"GET" toUrlString:urlString withVars:nil login:loginData error:errorPtr];
}

- (NSDictionary *)postRequestToUrlString:(NSString *)urlString withVars:(NSDictionary *)vars login:(NSDictionary *)loginData error:(NSError **)errorPtr
{
    return [self requestWithHTTPMethod:@"POST" toUrlString:urlString withVars:vars login:loginData error:errorPtr];
}

- (NSDictionary *)putRequestToUrlString:(NSString *)urlString withVars:(NSDictionary *)vars login:(NSDictionary *)loginData error:(NSError **)errorPtr
{
    return [self requestWithHTTPMethod:@"PUT" toUrlString:urlString withVars:vars login:loginData error:errorPtr];
}

- (NSDictionary *)requestWithHTTPMethod:(NSString *)httpMethod toUrlString:(NSString *)urlString withVars:(NSDictionary *)vars login:(NSDictionary *)loginData error:(NSError **)errorPtr
{
    NSDictionary *reply = nil;
    NSNumber *errorCode = nil;
    NSString *errorMessage = nil;

    if ([self noInternetConnectionAvailable]) {
        errorCode = @(-2);
    } else {
        NSURL *url = [NSURL URLWithString:urlString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        request.HTTPMethod = httpMethod;
        [request setValue:@"gzip" forHTTPHeaderField:@"accept-encoding"];

        if (loginData) {
            NSString *username = [loginData objectForKey:@"username"];
            NSString *password = [loginData objectForKey:@"password"];
            NSString *authString = [NSString stringWithFormat:@"%@:%@", username, password];
            NSData *authData = [authString dataUsingEncoding:NSUTF8StringEncoding];
            NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:0]];
            [request setValue:authValue forHTTPHeaderField:@"Authorization"];
        }

        if (vars) {
            [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];

            NSString *requestFields = @"";
            for (id key in vars) {
                requestFields = [requestFields stringByAppendingFormat:@"%@=%@&", key, [self percentEscapeString:[vars objectForKey:key]]];
            }
            request.HTTPBody = [requestFields dataUsingEncoding:NSUTF8StringEncoding];
        }
        
        NSHTTPURLResponse *response = nil;
        NSError *responseError = nil;
        NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&responseError];

        if (responseError) {
            switch ([responseError code]) {
                case -1012:
                    errorCode = @(401);
                    break;
                    
                default:
                    errorCode = @(-1);
                    break;
            }
        } else {
            NSError *jsonError;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&jsonError];

            switch (response.statusCode) {
                case 200:
                    reply = json;
                    break;

                case 404:
                    errorCode = @(404);
                    errorMessage = [NSString stringWithFormat:NSLocalizedString([errorCode stringValue], nil), [json objectForKey:@"error"]];
                    break;

                case 502:
                    errorCode = @(-1);
                    errorMessage = [NSString stringWithFormat:NSLocalizedString([errorCode stringValue], nil), [json objectForKey:@"error"]];
                    break;

                default:
                    errorCode = @(response.statusCode);
                    break;
            }
        }
    }

    if (errorCode) {
        *errorPtr = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier]
                                        code:[errorCode integerValue]
                                    userInfo:@{NSLocalizedDescriptionKey:errorMessage ?: NSLocalizedString([errorCode stringValue], nil)}];
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

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
        _errorMessages = @{@(-2):NSLocalizedString(@"No Internet Connection", nil),
                           @(-1):NSLocalizedString(@"Connection to M!service failed", nil),
                           @(400):NSLocalizedString(@"Please fill out the subject field", nil),
                           @(401):NSLocalizedString(@"Please verify your login data in settings", nil),
                           @(403):NSLocalizedString(@"Editing this message is no longer allowed", nil),
                           @(404):NSLocalizedString(@"Action could not be executed: %@", nil),
                           @(500):NSLocalizedString(@"Action could not be executed: an unknown error occured", nil),
                           @(504):NSLocalizedString(@"Man!ac Forum Server down?", nil)};
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

        NSDictionary *vars = @{@"username":inUsername,
                               @"password":inPassword};

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
    
    NSDictionary *vars = @{@"username":inUsername,
                           @"password":inPassword};
    
    
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

    NSDictionary *vars = @{@"username":inUsername,
                           @"password":inPassword};

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

    NSDictionary *vars = @{@"text":inText};

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
                           @"subject":inSubject,
                           @"text":inText,
                           @"username":inUsername,
                           @"password":inPassword,
                           @"notification":[NSString stringWithFormat:@"%d", inNotification]};
    
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

    NSDictionary *vars = @{@"subject":inSubject,
                           @"text":inText,
                           @"username":inUsername,
                           @"password":inPassword,
                           @"notification":[NSString stringWithFormat:@"%d", inNotification]};

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

    NSDictionary *vars = @{@"subject":inSubject,
                           @"text":inText,
                           @"username":inUsername,
                           @"password":inPassword};
    
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
    NSDictionary *vars = @{@"phrase":inPhrase};
    
    NSString *urlString = [NSString stringWithFormat:@"%@/board/%@/search-threads", kMServiceBaseURL, inBoardId];

    return [self postRequestToUrlString:urlString withVars:vars error:errorPtr];
}

- (NSDictionary *)getRequestToUrlString:(NSString *)urlString error:(NSError **)errorPtr
{
    return [self requestWithHTTPMethod:@"GET" toUrlString:urlString withVars:nil error:errorPtr];
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
    NSString *errorMessage = nil;

    if ([self noInternetConnectionAvailable]) {
        errorCode = @(-2);
    } else {
        NSURL *url = [NSURL URLWithString:urlString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        request.HTTPMethod = httpMethod;
        [request setValue:@"gzip" forHTTPHeaderField:@"accept-encoding"];

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
            errorCode = @(-1);
        } else {
            NSError *jsonError;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&jsonError];

            switch (response.statusCode) {
                case 200:
                    reply = json;
                    break;

                case 404:
                    errorCode = @(404);
                    errorMessage = [NSString stringWithFormat:[self.errorMessages objectForKey:errorCode], [json objectForKey:@"error"]];
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
                                    userInfo:@{NSLocalizedDescriptionKey:errorMessage ?: [self.errorMessages objectForKey:errorCode]}];
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

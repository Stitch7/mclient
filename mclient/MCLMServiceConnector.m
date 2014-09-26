//
//  MCLMServiceConnector.m
//  mclient
//
//  Created by Christopher Reitz on 02.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLMServiceConnector.h"

@implementation MCLMServiceConnector


- (NSArray *)errorMessages
{
    return @[@"Action could not be executed",               // :unknown
             @"Man!ac down?",                               // :connection
             @"Action could not be executed",               // :permission
             @"Please verify your login data in settings",  // :login
             @"Action could not be executed",               // :boardId
             @"Action could not be executed",               // :messageId
             @"Please fill out the subject field",          // :subject
             @"Editing this message is no longer allowed"]; // :answerExists
}

- (BOOL)testLoginWIthUsername:(NSString *)inUsername
                     password:(NSString *)inPassword
                        error:(NSError **)errorPtr
{
    BOOL success = NO;
    
    NSString *urlString = @"http://localhost:8000/test-login";
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    NSString *requestFields = [NSString stringWithFormat:@"username=%@&password=%@", [self percentEscapeString:inUsername], [self percentEscapeString:inPassword]];
    
    requestFields = [requestFields stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSData *requestData = [requestFields dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPBody = requestData;
    request.HTTPMethod = @"POST";
    
    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if (error == nil && response.statusCode == 200) {
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
        success = [[json objectForKey:@"success"] boolValue];
    } else {
        *errorPtr = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier]
                                        code:error.code
                                    userInfo:error.userInfo];
    }

    return success;
}

- (BOOL)notificationStatusForMessageId:(NSNumber *)inMessageId
                                    boardId:(NSNumber *)inBoardId
                                   username:(NSString *)inUsername
                                   password:(NSString *)inPassword
                                      error:(NSError **)errorPtr
{
    NSInteger notificationEnabled = -1;
    
    NSDictionary *vars = @{@"username":[self percentEscapeString:inUsername],
                           @"password":[self percentEscapeString:inPassword]};
    
    
    NSString *urlString = [NSString stringWithFormat:@"http://localhost:8000/board/%@/notification-status/%@", inBoardId, inMessageId];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    NSString *requestFields = @"";
    for (id key in vars) {
        requestFields = [requestFields stringByAppendingFormat:@"%@=%@&", key, [vars objectForKey:key]];
    }
    // requestFields = [requestFields stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSData *requestData = [requestFields dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPBody = requestData;
    request.HTTPMethod = @"POST";
    
    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if (error == nil && response.statusCode == 200) {
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
        notificationEnabled = [[json objectForKey:@"notificationEnabled"] integerValue];
    } else {
        NSLog(@"ERROR!");
    }
    
    return notificationEnabled;
}

- (BOOL)notificationForMessageId:(NSNumber *)inMessageId
                         boardId:(NSNumber *)inBoardId
                        username:(NSString *)inUsername
                        password:(NSString *)inPassword
                           error:(NSError **)errorPtr
{
    NSString *urlString = [NSString stringWithFormat:@"board/%@/notification/%@", inBoardId, inMessageId];

    NSDictionary *vars = @{@"username":[self percentEscapeString:inUsername],
                           @"password":[self percentEscapeString:inPassword]};

    return [self post:urlString withVars:vars error:errorPtr];
}


- (BOOL)quoteForMessageId:(NSNumber *)inMessageId
                       boardId:(NSNumber *)inBoardId
                         error:(NSError **)errorPtr
{
    BOOL success = YES;
    
    
    
    return success;
}

- (NSDictionary *)previewForMessageId:(NSNumber *)inMessageId
                              boardId:(NSNumber *)inBoardId
                              subject:(NSString *)inSubject
                                 text:(NSString *)inText
                             username:(NSString *)inUsername
                             password:(NSString *)inPassword
                                error:(NSError **)errorPtr
{
    NSDictionary *vars = @{@"boardId":inBoardId,
                           @"messageId":inMessageId ?: [NSNull null],
                           @"subject":[self percentEscapeString:inSubject],
                           @"text":[self percentEscapeString:inText],
                           @"username":[self percentEscapeString:inUsername],
                           @"password":[self percentEscapeString:inPassword],
                           @"notification":@0};

    BOOL success = NO;
    NSDictionary *content = nil;
    NSInteger errorCode = 0;
    NSDictionary *errorUserInfo = nil;

    NSString *urlString = [NSString stringWithFormat:@"http://localhost:8000/preview"];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    NSString *requestFields = @"";
    for (id key in vars) {
        requestFields = [requestFields stringByAppendingFormat:@"%@=%@&", key, [vars objectForKey:key]];
    }
    // requestFields = [requestFields stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSData *requestData = [requestFields dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPBody = requestData;
    request.HTTPMethod = @"POST";

    NSHTTPURLResponse *response = nil;
    NSError *responseError = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&responseError];

    if ( ! responseError) {
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&responseError];

        switch (response.statusCode) {
            case 200:
                success = [[json objectForKey:@"success"] boolValue];
                if (success) {
                    content = [json objectForKey:@"content"];
                } else {
                    errorCode = [[json objectForKey:@"errorCode"] integerValue];
                    errorUserInfo = @{ NSLocalizedDescriptionKey: [json objectForKey:@"errorMessage"],
                                       NSLocalizedFailureReasonErrorKey: [[self errorMessages] objectAtIndex:errorCode]};
                }
                break;
            case 500:
                errorUserInfo = @{ NSLocalizedDescriptionKey: [json objectForKey:@"code"],
                                   NSLocalizedFailureReasonErrorKey: [[self errorMessages] objectAtIndex:0]};
                NSLog(@"%@: %@", [json objectForKey:@"code"], [json objectForKey:@"message"]);
                break;
        }
    } else {
        NSLog(@"responseError: %@", responseError);
    }

    if ( ! success) {
        *errorPtr = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier]
                                        code:errorCode
                                    userInfo:errorUserInfo];
    }

    return content;
}


- (BOOL)postThreadToBoardId:(NSNumber *)inBoardId
                    subject:(NSString *)inSubject
                       text:(NSString *)inText
                   username:(NSString *)inUsername
                   password:(NSString *)inPassword
               notification:(BOOL)inNotification
                      error:(NSError **)errorPtr
{
    NSDictionary *vars = @{@"boardId":inBoardId,
                           @"messageId":@"",
                           @"subject":[self percentEscapeString:inSubject],
                           @"text":[self percentEscapeString:inText],
                           @"username":[self percentEscapeString:inUsername],
                           @"password":[self percentEscapeString:inPassword],
                           @"notification":[NSNumber numberWithBool:inNotification]};
    
    return [self post:@"post" withVars:vars error:errorPtr];
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
    NSDictionary *vars = @{@"boardId":inBoardId,
                           @"messageId":inMessageId,
                           @"subject":[self percentEscapeString:inSubject],
                           @"text":[self percentEscapeString:inText],
                           @"username":[self percentEscapeString:inUsername],
                           @"password":[self percentEscapeString:inPassword],
                           @"notification":[NSNumber numberWithBool:inNotification]};
    
    return [self post:@"post" withVars:vars error:errorPtr];
}

- (BOOL)postEditToMessageId:(NSNumber *)inMessageId
                    boardId:(NSNumber *)inBoardId
                    subject:(NSString *)inSubject
                       text:(NSString *)inText
                   username:(NSString *)inUsername
                   password:(NSString *)inPassword
                      error:(NSError **)errorPtr
{
    NSDictionary *vars = @{@"boardId":inBoardId,
                           @"messageId":inMessageId,
                           @"subject":[self percentEscapeString:inSubject],
                           @"text":[self percentEscapeString:inText],
                           @"username":[self percentEscapeString:inUsername],
                           @"password":[self percentEscapeString:inPassword],
                           @"notification":@0};
    
    return [self post:@"edit" withVars:vars error:errorPtr];
}

- (NSData *)searchOnBoard:(NSNumber *)inBoardId
               withPhrase:(NSString *)inPhrase
                    error:(NSError **)errorPtr
{
    
    NSDictionary *vars = @{@"phrase":[self percentEscapeString:inPhrase]};
    
    NSString *urlString = [NSString stringWithFormat:@"http://localhost:8000/board/%@/search", inBoardId];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    NSString *requestFields = @"";
    for (id key in vars) {
        requestFields = [requestFields stringByAppendingFormat:@"%@=%@&", key, [vars objectForKey:key]];
    }
    // requestFields = [requestFields stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSData *requestData = [requestFields dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPBody = requestData;
    request.HTTPMethod = @"POST";
    
    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if (error == nil && response.statusCode == 200) {
        //        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
        //        notificationEnabled = [[json objectForKey:@"notificationEnabled"] integerValue];
    } else {
        NSLog(@"ERROR!");
    }
    
    return responseData;
}

- (BOOL)post:(NSString *)action withVars:(NSDictionary *)vars error:(NSError **)errorPtr
{
    BOOL success = NO;
    NSInteger errorCode = 0;
    NSDictionary *errorUserInfo = nil;
    
    NSString *urlString = [NSString stringWithFormat:@"http://localhost:8000/%@", action];    
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    NSString *requestFields = @"";
    for (id key in vars) {
        requestFields = [requestFields stringByAppendingFormat:@"%@=%@&", key, [vars objectForKey:key]];
    }
    // requestFields = [requestFields stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSData *requestData = [requestFields dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPBody = requestData;
    request.HTTPMethod = @"POST";
    
    NSHTTPURLResponse *response = nil;
    NSError *responseError = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&responseError];
    
    if ( ! responseError) {
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&responseError];

        switch (response.statusCode) {
            case 200:
                success = [[json objectForKey:@"success"] boolValue];
                if ( ! success) {
                    errorCode = [[json objectForKey:@"errorCode"] integerValue];
                    errorUserInfo = @{ NSLocalizedDescriptionKey: [json objectForKey:@"errorMessage"],
                                       NSLocalizedFailureReasonErrorKey: [[self errorMessages] objectAtIndex:errorCode]};
                }
                break;
            case 500:
                errorUserInfo = @{ NSLocalizedDescriptionKey: [json objectForKey:@"code"],
                                   NSLocalizedFailureReasonErrorKey: [[self errorMessages] objectAtIndex:0]};
                NSLog(@"%@: %@", [json objectForKey:@"code"], [json objectForKey:@"message"]);
                break;
        }
    } else {
        NSLog(@"responseError: %@", responseError);
    }

    if ( ! success) {
        *errorPtr = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier]
                                        code:errorCode
                                    userInfo:errorUserInfo];
    }

    return success;
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

//
//  MCLMServiceConnector.m
//  mclient
//
//  Created by Christopher Reitz on 02.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLMServiceConnector.h"

@implementation MCLMServiceConnector

- (BOOL)testLoginWIthUsername:(NSString *)inUsername password:(NSString *)inPassword
{
    BOOL success = NO;
    
    NSString *urlString = @"http://localhost:8000/test-login";
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    NSString *requestFields = [NSString stringWithFormat:@"username=%@&password=%@", inUsername, inPassword];
    
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
        NSLog(@"ERROR!");
    }
    
    return success;
}

- (NSInteger)quoteForMessageId:(NSNumber *)inMessageId boardId:(NSNumber *)inBoardId
{
    NSInteger code;
    
    
    
    return code;
}


- (BOOL)postThreadToBoardId:(NSNumber *)inBoardId subject:(NSString *)inSubject text:(NSString *)inText username:(NSString *)inUsername password:(NSString *)inPassword notification:(NSNumber *)inNotification
{
    return [self post:@"post" withVars:@{@"boardId":inBoardId,
                                         @"messageId":@"",
                                         @"subject":inSubject,
                                         @"text":inText,
                                         @"username":inUsername,
                                         @"password":inPassword,
                                         @"notification":inNotification}];
}

- (BOOL)postReplyToMessageId:(NSNumber *)inMessageId boardId:(NSNumber *)inBoardId subject:(NSString *)inSubject text:(NSString *)inText username:(NSString *)inUsername password:(NSString *)inPassword notification:(NSNumber *)inNotification
{
    return [self post:@"post" withVars:@{@"boardId":inBoardId,
                                         @"messageId":inMessageId,
                                         @"subject":inSubject,
                                         @"text":inText,
                                         @"username":inUsername,
                                         @"password":inPassword,
                                         @"notification":inNotification}];
}

- (BOOL)postEditToMessageId:(NSNumber *)inMessageId boardId:(NSNumber *)inBoardId subject:(NSString *)inSubject text:(NSString *)inText username:(NSString *)inUsername password:(NSString *)inPassword
{
    return [self post:@"edit" withVars:@{@"boardId":inBoardId,
                                          @"messageId":inMessageId,
                                          @"subject":inSubject,
                                          @"text":inText,
                                          @"username":inUsername,
                                          @"password":inPassword,
                                          @"notification":@0}];
}

- (NSUInteger)post:(NSString *)action withVars:(NSDictionary *)vars
{
    NSUInteger success = 1;
    
    NSString *urlString = [NSString stringWithFormat:@"http://localhost:8000/%@", action];
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    NSString *requestFields = @"";
    for (id key in vars) {
        requestFields = [requestFields stringByAppendingFormat:@"%@=%@&", key, [vars objectForKey:key]];
    }    
    requestFields = [requestFields stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSData *requestData = [requestFields dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPBody = requestData;
    request.HTTPMethod = @"POST";
    
    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if (error == nil && response.statusCode == 200) {
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
        success = [[json objectForKey:@"success"] integerValue];
    } else {
        NSLog(@"ERROR!");
    }
    
    return success;
}

@end

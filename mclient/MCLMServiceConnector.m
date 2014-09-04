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

- (BOOL)postThreadToBoardId:(NSNumber *)inBoardId subject:(NSString *)inSubject text:(NSString *)inText username:(NSString *)inUsername password:(NSString *)inPassword notification:(BOOL)inNotification
{
    BOOL success = NO;
    
    NSString *urlString = @"http://localhost:8000/post";
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    NSString *requestFields = [NSString stringWithFormat:@"boardId=%@&messageId=%@&subject=%@&text=%@&username=%@&password=%@&notification=%hhd", inBoardId, @"", inSubject, inText, inUsername, inPassword, inNotification];
    
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

- (BOOL)postReplyToMessageId:(NSNumber *)inMessageId boardId:(NSNumber *)inBoardId subject:(NSString *)inSubject text:(NSString *)inText username:(NSString *)inUsername password:(NSString *)inPassword notification:(BOOL)inNotification
{
    BOOL success = NO;
    
    NSString *urlString = @"http://localhost:8000/post";
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    NSString *requestFields = [NSString stringWithFormat:@"boardId=%@&messageId=%@&subject=%@&text=%@&username=%@&password=%@&notification=%hhd", inBoardId, inMessageId, inSubject, inText, inUsername, inPassword, inNotification];
    
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

- (BOOL)postEditToMessageId:(NSNumber *)inMessageId boardId:(NSNumber *)inBoardId subject:(NSString *)inSubject text:(NSString *)inText username:(NSString *)inUsername password:(NSString *)inPassword
{
    BOOL success = NO;
    
    return success;
}

@end

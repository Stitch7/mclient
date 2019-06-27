//
//  MCLPrivateMessage.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLPrivateMessage.h"

@implementation MCLPrivateMessage

+ (MCLPrivateMessage *)privateMessageFromJSON:(NSDictionary *)json
{
    NSDateFormatter *dateFormatterForInput = [[NSDateFormatter alloc] init];
    [dateFormatterForInput setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    [dateFormatterForInput setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    NSDate *date = [dateFormatterForInput dateFromString:[json objectForKey:@"date"]];

    MCLPrivateMessage *privateMessage = [[MCLPrivateMessage alloc] init];
    privateMessage.messageId = [json objectForKey:@"msgid"];
    privateMessage.date = date;
    privateMessage.subject = [json objectForKey:@"subject"];
//    privateMessage.text = [json objectForKey:@"text"];
    privateMessage.type = [json objectForKey:@"type"];

    id isReadOpt = [json objectForKey:@"isRead"];
    privateMessage.read = (isReadOpt != (id)[NSNull null] && isReadOpt != nil) ? [isReadOpt boolValue] : YES;

    return  privateMessage;
}

+ (MCLPrivateMessage *)privateMessageWithPropertyList:(NSDictionary *)propertyList
{
    MCLPrivateMessage *privateMessage = [[MCLPrivateMessage alloc] init];

    privateMessage.messageId = [propertyList valueForKey:@"messageId"];
    privateMessage.date = [propertyList valueForKey:@"date"];
    privateMessage.username = [propertyList valueForKey:@"username"];
    privateMessage.subject = [propertyList valueForKey:@"subject"];
    privateMessage.text = [propertyList valueForKey:@"text"];
    privateMessage.type = [propertyList valueForKey:@"type"];
    privateMessage.read = [[propertyList valueForKey:@"read"] boolValue];

    return privateMessage;
}

#pragma mark - Computed properties

- (NSDictionary *)propertyList
{
    return @{@"messageId": self.messageId,
             @"date": self.date,
             @"username": self.username,
             @"subject": self.subject,
             @"text": self.text ?: @"",
             @"type": self.type,
             @"read": [NSNumber numberWithBool:self.read]};
}

@end

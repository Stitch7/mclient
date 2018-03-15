//
//  MCLMessage.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLMessage.h"

#import "Reachability.h"
#import "UIColor+Hex.h"
#import "MCLSettings.h"
#import "MCLTheme.h"
#import "MCLBoard.h"
#import "MCLThread.h"
#import "MCLResponse.h"

@implementation MCLMessage

+ (MCLMessage *)messageWithId:(NSNumber *)inMessageId
                         read:(BOOL)inRead
                        level:(NSNumber *)inLevel
                          mod:(BOOL)inMod
                     username:(NSString *)inUsername
                      subject:(NSString *)inSubject
                         date:(NSDate *)inDate
{
    MCLMessage *message = [[MCLMessage alloc] init];
    message.messageId = inMessageId;
    message.read = inRead;
    message.level = inLevel;
    message.username = inUsername;
    message.mod = inMod;
    message.subject = inSubject;
    message.date = inDate;

    return message;
}

+ (MCLMessage *)messageFromResponse:(MCLResponse *)response
{
    MCLMessage *message = [[MCLMessage alloc] init];
    message.board = [MCLBoard boardWithId:response.boardId];
    message.thread = [MCLThread threadWithId:response.threadId
                                     subject:response.threadSubject];
    message.thread.boardId = response.boardId;
    message.thread.board = message.board;
    message.boardId = response.boardId;
    message.messageId = response.messageId;
    message.subject = response.subject;
    message.username = response.username;
    message.date = response.date;
    message.read = response.read;
//    response.tempRead = inRead;

    return message;
}

+ (MCLMessage *)messageFromJSON:(NSDictionary *)json
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];

    NSNumber *messageId = [json objectForKey:@"messageId"];
    id isReadOpt = [json objectForKey:@"isRead"];
    BOOL isRead = (isReadOpt != (id)[NSNull null] && isReadOpt != nil) ? [isReadOpt boolValue] : YES;
    NSNumber *level = [json objectForKey:@"level"];
    BOOL mod = [[json objectForKey:@"mod"] boolValue];
    NSString *username = [json objectForKey:@"username"];
    NSString *subject = [json objectForKey:@"subject"];
    NSDate *date = [dateFormatter dateFromString:[json objectForKey:@"date"]];

    MCLMessage *message = [MCLMessage messageWithId:messageId
                                               read:isRead
                                              level:level
                                                mod:mod
                                           username:username
                                            subject:subject
                                               date:date];

    return message;
}

- (void)updateFromMessageTextJSON:(NSDictionary *)json
{
    self.userId = [json objectForKey:@"userId"];
    self.text = [json objectForKey:@"text"];
    self.textHtml = [json objectForKey:@"textHtml"];
    self.textHtmlWithImages = [json objectForKey:@"textHtmlWithImages"];
    if ([json objectForKey:@"notification"] != [NSNull null]) {
        self.notification = [[json objectForKey:@"notification"] boolValue];
    }
}

- (NSString *)messageHtmlWithTopMargin:(int)topMargin theme:(id <MCLTheme>)theme imageSetting:(NSNumber *)imageSetting
{
    NSString *messageHtml = @"";
    switch ([imageSetting integerValue]) {
        case kMCLSettingsShowImagesAlways:
        default:
            messageHtml = self.textHtmlWithImages;
            break;

        case kMCLSettingsShowImagesWifi: {
            Reachability *wifiReach = [Reachability reachabilityForLocalWiFi];
            messageHtml = [wifiReach currentReachabilityStatus] == ReachableViaWiFi
                ? self.textHtmlWithImages
                : self.textHtml;
            break;
        }
        case kMCLSettingsShowImagesNever:
            messageHtml = self.textHtml;
            break;
    }

    return [self messageHtmlSkeletonForHtml:messageHtml
                              withTopMargin:topMargin
                                   andTheme:theme];
}

# pragma mark - Private Methods

- (NSString *)messageHtmlSkeletonForHtml:(NSString *)html withTopMargin:(int)topMargin andTheme:(id <MCLTheme>)currentTheme
{
    NSInteger fontSizeValue = [[NSUserDefaults standardUserDefaults] integerForKey:@"fontSize"];
    if (!fontSizeValue) {
        fontSizeValue = 3;
    }

    NSInteger buttonFontSizeValue = fontSizeValue + 9;
    fontSizeValue = fontSizeValue + 11;

    // TODO: crash?
    NSString *fontSize = [@(fontSizeValue) stringValue];
    NSString *buttonFontSize = [@(buttonFontSizeValue) stringValue];

//        NSString *fontSize = [NSString stringWithFormat:@"%ldpx", (long)(fontSizeValue + 11)];
//        NSString *buttonFontSize = [NSString stringWithFormat:@"%ldpx", (long)(fontSizeValue + 9)];
//    NSString *fontSize = @"14";
//    NSString *buttonFontSize = @"14";

    NSString *textColor = [currentTheme isDark] ? @"#fff" : @"#000";
    NSString *linkColor = [currentTheme cssTintColor];

    return [NSString stringWithFormat:@""
            "<html>"
            "<head>"
            "<meta name=\"viewport\" content=\"initial-scale=1.0\"/>"
            "<script type=\"text/javascript\">"
            "    function spoiler(obj) {"
            "        if (obj.nextSibling.style.display === 'none') {"
            "            obj.nextSibling.style.display = 'inline';"
            "        } else {"
            "            obj.nextSibling.style.display = 'none';"
            "        }"
            "        window.webkit.messageHandlers.mclient.postMessage({\"message\":\"content-changed\"});"
            "    }"
            "</script>"
            "<style>"
            "    * {"
            "        font-family: \"Helvetica Neue\";"
            "        font-size: %@;"
            "        -webkit-text-size-adjust: none;"
            "    }"
            "    body {"
            "        margin: %ipx 20px 10px 20px;"
            "        padding: 0px;"
            "        background-color: transparent;"
            "        color: %@;"
            "    }"
            "    a {"
            "        word-break: break-all;"
            "        color: %@;"
            "    }"
            "    img {"
            "        max-width: 100%%;"
            "    }"
            "    button {"
            "        border-radius: 3px;"
            "        color: #0a60ff;"
            "        font-size: %@;"
            "        padding: 3px 7px;"
            "        border: solid #0a60ff 1px;"
            "        text-decoration: none;"
            "    }"
            "</style>"
            "</head>"
            "<body>%@</body>"
            "</html>", fontSize, topMargin, textColor, linkColor, buttonFontSize, html];
}

@end

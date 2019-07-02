//
//  MCLMessage.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLMessage.h"

#import "Reachability.h"
#import "UIColor+Hex.h"
#import "MCLSettings.h"
#import "MCLTheme.h"
#import "MCLDraft.h"
#import "MCLBoard.h"
#import "MCLThread.h"
#import "MCLResponse.h"


@implementation MCLMessage

# pragma mark - Initializers

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

+ (MCLMessage *)messagePreviewWithType:(NSUInteger)type
                             messageId:(NSNumber *)inMessageId
                                 board:(MCLBoard *)inBoard
                              threadId:(NSNumber *)inThreadId
                               subject:(NSString *)inSubject
                                  text:(NSString *)inText
{
    MCLMessage *message = [[MCLMessage alloc] init];
    message.type = type;
    message.messageId = inMessageId;
    message.board = inBoard;
    message.thread = [MCLThread threadWithId:inThreadId];
    message.thread.boardId = inBoard.boardId;
    message.thread.board = message.board;
    message.boardId = inBoard.boardId;
    message.subject = inSubject;
    message.text = inText;

    return message;
}

+ (MCLMessage *)messageNewWithBoard:(MCLBoard *)board
{
    MCLMessage *message = [[MCLMessage alloc] init];
    message.boardId = board.boardId;
    message.board = board;

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

    return message;
}

+ (MCLMessage *)messageFromDraft:(MCLDraft *)draft
{
    if (!draft) { return nil; }

    MCLMessage *message = [[MCLMessage alloc] init];
    message.isDraft = YES;
    message.type = draft.type;
    message.board = [MCLBoard boardWithId:draft.boardId name:draft.boardName];
    message.thread = [MCLThread threadWithId:draft.threadId
                                     subject:draft.originalSubject];
    message.thread.boardId = draft.boardId;
    message.thread.board = message.board;
    message.boardId = draft.boardId;
    message.messageId = draft.messageId;
    message.subject = draft.subject;
    message.text = draft.text;

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

    message.text = [json objectForKey:@"text"];

    return message;
}

+ (MCLMessage *)messageFromSearchResultJSON:(NSDictionary *)json
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];

    NSNumber *boardId = [json objectForKey:@"boardId"];
    NSNumber *threadId = [json objectForKey:@"threadId"];
    NSNumber *messageId = [json objectForKey:@"messageId"];
    NSString *username = [json objectForKey:@"username"];
    NSString *subject = [json objectForKey:@"subject"];
    NSDate *date = [dateFormatter dateFromString:[json objectForKey:@"date"]];

    MCLMessage *message = [MCLMessage messageWithId:messageId
                                               read:YES
                                              level:0
                                                mod:NO
                                           username:username
                                            subject:subject
                                               date:date];

    message.boardId = boardId;
    message.board = [MCLBoard boardWithId:boardId];
    message.thread = [MCLThread threadWithId:threadId subject:subject];
    message.thread.board = message.board;

    return message;
}

# pragma mark - Public Methods

- (void)updateFromMessageTextJSON:(NSDictionary *)json
{
    self.userId = [json objectForKey:@"userId"];
    self.text = [json objectForKey:@"text"];
    self.textHtml = [json objectForKey:@"textHtml"];
    self.textHtmlWithImages = [json objectForKey:@"textHtmlWithImages"];
    if ([json objectForKey:@"notification"] != [NSNull null]) {
        self.notification = [[json objectForKey:@"notification"] boolValue];
    }
    if ([json objectForKey:@"userBlockedByYou"] != [NSNull null]) {
        self.userBlockedByYou = [[json objectForKey:@"userBlockedByYou"] boolValue];
    }
    if ([json objectForKey:@"userBlockedYou"] != [NSNull null]) {
        self.userBlockedYou = [[json objectForKey:@"userBlockedYou"] boolValue];
    }
}

- (NSString *)key
{
    return [NSString stringWithFormat:@"%@-%@-%@", self.board.boardId, self.thread.threadId, self.messageId];
}

- (MCLDraft *)draft
{
    MCLDraft *draft = [[MCLDraft alloc] init];
    draft.type = self.type;
    draft.boardId = self.boardId;
    draft.boardName = self.board.name;
    draft.threadId = self.thread.threadId;
    draft.messageId = self.messageId;
    draft.originalSubject = self.prevMessage.subject;
    draft.subject = self.subject;
    draft.text = self.text;
    draft.date = [NSDate new];

    return draft;
}

- (NSString *)messageHtmlWithTopMargin:(int)topMargin width:(CGFloat)width theme:(id <MCLTheme>)theme settings:(MCLSettings *)settings
{
    int leftRightMargin = 20;
    CGFloat youtubeFameWidth = width - leftRightMargin * 2;
    NSNumber *imageSetting = [settings objectForSetting:MCLSettingShowImages];
    NSInteger fontSize = [settings integerForSetting:MCLSettingFontSize orDefault:kSettingsDefaultFontSize];
    BOOL classicQuoteDesign = [settings isSettingActivated:MCLSettingClassicQuoteDesign];
    BOOL embedYoutube = [settings isSettingActivated:MCLSettingEmbedYoutubeVideos];

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
                                  topMargin:topMargin
                            leftRightMargin:leftRightMargin
                          youtubeFrameWidth:youtubeFameWidth
                                   fontSize:fontSize
                         classicQuoteDesign:classicQuoteDesign
                               embedYoutube:embedYoutube
                                      theme:theme];
}

# pragma mark - Private Methods

- (NSString *)messageHtmlSkeletonForHtml:(NSString *)html
                               topMargin:(int)topMargin
                         leftRightMargin:(int)leftRightMargin
                       youtubeFrameWidth:(int)youtubeFrameWidth
                                fontSize:(NSInteger)fontSize
                      classicQuoteDesign:(BOOL)classicQuoteDesign
                            embedYoutube:(BOOL)embedYoutube
                                   theme:(id <MCLTheme>)currentTheme
{
    NSString *editedHtml = html;
    if (!classicQuoteDesign) {
        editedHtml = [editedHtml stringByReplacingOccurrencesOfString:@" color=\"#808080\"" withString:@""]; // regular message
        editedHtml = [editedHtml stringByReplacingOccurrencesOfString:@" color=\"808080\"" withString:@""]; // message preview
        editedHtml = [editedHtml stringByReplacingOccurrencesOfString:@"<font>&gt;" withString:@"<font>"];
        editedHtml = [editedHtml stringByReplacingOccurrencesOfString:@"<br>\n&gt;" withString:@"<br>"];
    }

    NSInteger buttonFontSizeValue = fontSize + 9;
    fontSize += 11;
    NSString *fontSizeStr = [@(fontSize) stringValue];
    NSString *buttonFontSize = [@(buttonFontSizeValue) stringValue];

    NSString *textColor = [currentTheme isDark] ? @"fff" : @"000";
    NSString *linkColor = [currentTheme cssTintColor];
    NSString *classicQuoteDesignDisabled = classicQuoteDesign ? @"-DEACTIVATED" : @"";
    NSString *embedYoutubeEnabled = embedYoutube ? @"true" : @"false";
    NSString *quoteColor = [currentTheme cssQuoteColor];

    NSString *messageHtml =
        [NSString stringWithFormat:@""
            "<html>"
            "<head>"
            "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no\"/>"
            "<script type=\"text/javascript\">"
            "    spoiler = (obj) => {"
            "        if (obj.nextSibling.style.display === 'none') {"
            "            obj.nextSibling.style.display = 'inline';"
            "        } else {"
            "            obj.nextSibling.style.display = 'none';"
            "        }"
            "        window.webkit.messageHandlers.mclient.postMessage({\"message\":\"content-changed\"});"
            "    };"
            " "
            "    transformYoutubeLinks = (text) => {"
            "        const self = this;"
            "        let resultHtml = text;"
            " "
            "        parseYoutubeURL = (url) => {"
            "            const regExp = \"^(?:https?:)?//[^/]*(?:youtube(?:-nocookie)?\\.com|youtu\\.be).*[=/]([-\\\\w]{11})(?:\\\\?|=|&|$)\";"
            "            const match = url.match(regExp);"
            "            return match ? match[1] : false;"
            "        };"
            " "
            "        startTimeFromYoutubeURL = (url) => {"
            "            const queryString = url.split('?').pop();"
            "            const urlParams = new URLSearchParams(queryString);"
            "            const startParam = urlParams.get('start') || urlParams.get('t') || '0s';"
            "            return startParam.replace('s', '');"
            "        };"
            " "
            "        createYoutubeEmbed = (id, startTime) => {"
            "            const width = %i;" // youtubeFrameWidth
            "            const height = width * 0.5625;"
            "            return '<iframe width=\"' + width + '\" height=\"' + height + '\" src=\"https://www.youtube.com/embed/' + id + '?start=' + startTime + '\" frameborder=\"0\" allowfullscreen></iframe>';"
            "        };"
            " "
            "        for (const link of document.getElementsByTagName('a')) {"
            "            if (link.parentElement.tagName === 'FONT') {"
            "               continue;"
            "            }"
            "            const youtubeID = self.parseYoutubeURL(link.href);"
            "            if (youtubeID) {"
            "                const startTime = self.startTimeFromYoutubeURL(link.href);"
            "                resultHtml = resultHtml.replace(link.outerHTML, self.createYoutubeEmbed(youtubeID, startTime) + '<br>' + link.outerHTML + '<br>');"
            "            }"
            "        }"
            "        return resultHtml;"
            "    };"
            "</script>"
            "<style>"
            "    * {"
            "        font-family: \"Helvetica Neue\";"
            "        font-size: %@;" // fontSizeStr
            "        -webkit-text-size-adjust: none;"
            "    }"
            "    body {"
            "        margin: %ipx %ipx 10px %ipx;" // topMargin, leftRightMargin, leftRightMargin
            "        padding: 0px;"
            "        background-color: transparent;"
            "        color: #%@;" // textColor
            "    }"
            "    a {"
            "        word-break: break-all;"
            "        color: #%@;" // linkColor
            "    }"
            "    font%@ {" // classicQuoteDesignDisabled
            "        display: block;"
            "        padding-left: 10px;"
            "        margin-bottom: -15px;"
            "        border-left: 2px solid;"
            "        border-color: #%@;" // quoteColor
            "        color: #%@;" // quoteColor
            "    }"
            "    img {"
            "        max-width: 100%%;"
            "    }"
            "    button {"
            "        border-radius: 3px;"
            "        color: #0a60ff;"
            "        font-size: %@;" // buttonFontSize
            "        font-weight: bold;"
            "        padding: 3px 7px;"
            "        border: solid #0a60ff 1px;"
            "        text-decoration: none;"
            "    }"
            "</style>"
            "</head>"
            "<body>%@</body>" // editedHtml
            "<script type=\"text/javascript\">"
            "   if (%@) {" // embedYoutubeEnabled
            "       const content = document.getElementById('content');"
            "       const newContentInnerHTML = transformYoutubeLinks(content.innerHTML);"
            "       if (content.innerHTML !== newContentInnerHTML) {"
            "           content.innerHTML = newContentInnerHTML;"
            "           window.webkit.messageHandlers.mclient.postMessage({\"message\":\"content-changed\"});"
            "       }"
            "   }"
            "</script>"
            "</html>",
            youtubeFrameWidth,
            fontSizeStr,
            topMargin,
            leftRightMargin,
            leftRightMargin,
            textColor,
            linkColor,
            classicQuoteDesignDisabled,
            quoteColor,
            quoteColor,
            buttonFontSize,
            editedHtml,
            embedYoutubeEnabled];

    return messageHtml;
}

- (NSString *)actionTitle
{
    switch (self.type) {
        case kMCLComposeTypeThread:
            return NSLocalizedString(@"Create Thread", nil);

        case kMCLComposeTypeReply:
            return NSLocalizedString(@"Reply", nil);

        case kMCLComposeTypeEdit:
            return NSLocalizedString(@"Edit", nil);
    }

    return nil;
}

@end

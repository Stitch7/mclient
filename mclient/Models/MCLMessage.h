//
//  MCLMessage.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLTheme;

@class MCLBoard;
@class MCLThread;
@class MCLResponse;

typedef NS_ENUM(NSUInteger, kMCLComposeType) {
    kMCLComposeTypeThread,
    kMCLComposeTypeReply,
    kMCLComposeTypeEdit
};

@interface MCLMessage : NSObject

@property (strong, nonatomic) MCLBoard *board;
@property (strong, nonatomic) MCLThread *thread;
@property (strong, nonatomic) MCLMessage *nextMessage;

@property (strong) NSNumber *boardId;
@property (strong) NSNumber *messageId;
@property (assign, nonatomic, getter=isRead) BOOL read;
@property (strong) NSNumber *level;
@property (strong) NSNumber *userId;
@property (assign, nonatomic, getter=isMod) BOOL mod;
@property (strong) NSString *username;
@property (strong) NSString *subject;
@property (strong) NSDate *date;
@property (strong) NSString *text;
@property (strong) NSString *textHtml;
@property (strong) NSString *textHtmlWithImages;
@property (assign, nonatomic) BOOL notification;
@property (assign, nonatomic) BOOL userBlockedByYou;
@property (assign, nonatomic) BOOL userBlockedYou;

@property (assign) NSUInteger type;

+ (MCLMessage *)messageWithId:(NSNumber *)inMessageId
                         read:(BOOL)inRead
                        level:(NSNumber *)inLevel
                          mod:(BOOL)inMod
                     username:(NSString *)inUsername
                      subject:(NSString *)inSubject
                         date:(NSDate *)inDate;

+ (MCLMessage *)messagePreviewWithType:(NSUInteger)type
                             messageId:(NSNumber *)inMessageId
                               boardId:(NSNumber *)inBoardId
                              threadId:(NSNumber *)inThreadId
                               subject:(NSString *)inSubject
                                  text:(NSString *)inText;

+ (MCLMessage *)messageNewWithBoard:(MCLBoard *)board;

+ (MCLMessage *)messageFromResponse:(MCLResponse *)response;

+ (MCLMessage *)messageFromJSON:(NSDictionary *)json;

- (void)updateFromMessageTextJSON:(NSDictionary *)json;
- (NSString *)messageHtmlWithTopMargin:(int)topMargin theme:(id <MCLTheme>)theme imageSetting:(NSNumber *)imageSetting;

@end

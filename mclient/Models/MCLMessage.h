//
//  MCLMessage.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@protocol MCLTheme;

@class MCLDraft;
@class MCLBoard;
@class MCLThread;
@class MCLResponse;
@class MCLSettings;

typedef NS_ENUM(NSUInteger, kMCLComposeType) {
    kMCLComposeTypeThread,
    kMCLComposeTypeReply,
    kMCLComposeTypeEdit
};

@interface MCLMessage : NSObject

@property (strong, nonatomic) MCLBoard *board;
@property (strong, nonatomic) MCLThread *thread;
@property (strong, nonatomic) MCLMessage *prevMessage;
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

@property (assign, nonatomic) BOOL isDraft;
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
                                 board:(MCLBoard *)inBoard
                              threadId:(NSNumber *)inThreadId
                               subject:(NSString *)inSubject
                                  text:(NSString *)inText;

+ (MCLMessage *)messageNewWithBoard:(MCLBoard *)board;
+ (MCLMessage *)messageFromResponse:(MCLResponse *)response;
+ (MCLMessage *)messageFromJSON:(NSDictionary *)json;
+ (MCLMessage *)messageFromSearchResultJSON:(NSDictionary *)json;
+ (MCLMessage *)messageFromDraft:(MCLDraft *)draft;

- (void)updateFromMessageTextJSON:(NSDictionary *)json;

- (NSString *)key;

- (MCLDraft *)draft;

- (NSString *)messageHtmlWithTopMargin:(int)topMargin
                                 width:(CGFloat)width
                                 theme:(id <MCLTheme>)theme
                              settings:(MCLSettings *)settings;

- (NSString *)actionTitle;

@end

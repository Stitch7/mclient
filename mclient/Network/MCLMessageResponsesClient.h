//
//  MCLMessageResponsesClient.h
//  mclient
//
//  Created by Christopher Reitz on 28/02/2017.
//  Copyright © 2017 Christopher Reitz. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const MCLMessageResponsesClientFoundUnreadResponsesNotification;

@interface MCLMessageResponsesClient : NSObject

@property (nonatomic, copy) NSDictionary *responses;
@property (nonatomic, copy) NSMutableArray *sectionKeys;
@property (nonatomic, copy) NSMutableDictionary *sectionTitles;

+ (id)sharedClient;
- (void)loadDataWithCompletion:(void (^)(NSDictionary *responses, NSArray *sectionKeys, NSDictionary *sectionTitles))completion;
- (NSArray *)unreadResponses;
- (NSInteger)numberOfUnreadResponses;

@end

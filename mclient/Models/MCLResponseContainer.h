//
//  MCLResponseContainer.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLResponse.h"

@interface MCLResponseContainer : NSObject

@property (nonatomic, readonly, copy) NSDictionary *responses;
@property (nonatomic, readonly, copy) NSArray *sectionKeys;
@property (nonatomic, readonly, copy) NSDictionary *sectionTitles;

- (instancetype)initWithResponses:(NSDictionary *)responses sectionKeys:(NSArray *)sectionKeys andTitles:(NSDictionary *)sectionTitles;

- (NSArray *)messagesInSection:(NSInteger)section;
- (MCLResponse *)responseForIndexPath:(NSIndexPath *)indexPath;
- (NSArray *)unreadResponses;
- (NSInteger)numberOfUnreadResponses;

@end

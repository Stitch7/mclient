//
//  MCLResponseContainer.h
//  mclient
//
//  Created by Christopher Reitz on 28/03/2017.
//  Copyright © 2017 Christopher Reitz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCLResponse.h"

@interface MCLResponseContainer : NSObject

@property (nonatomic, readonly, copy) NSDictionary *responses;
@property (nonatomic, readonly, copy) NSArray *sectionKeys;
@property (nonatomic, readonly, copy) NSDictionary *sectionTitles;

- (id)initWithResponses:(NSDictionary *)responses sectionKeys:(NSArray *)sectionKeys andTitles:(NSDictionary *)sectionTitles;
- (NSArray *)messagesInSection:(NSInteger)section;
- (MCLResponse *)responseForIndexPath:(NSIndexPath *)indexPath;
- (NSArray *)unreadResponses;
- (NSInteger)numberOfUnreadResponses;

@end

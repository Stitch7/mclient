//
//  MCLResponseContainer.m
//  mclient
//
//  Created by Christopher Reitz on 28/03/2017.
//  Copyright © 2017 Christopher Reitz. All rights reserved.
//

#import "MCLResponseContainer.h"

@interface MCLResponseContainer ()

@property (nonatomic, copy) NSDictionary *responses;
@property (nonatomic, copy) NSArray *sectionKeys;
@property (nonatomic, copy) NSDictionary *sectionTitles;

@end

@implementation MCLResponseContainer

- (id)initWithResponses:(NSDictionary *)responses sectionKeys:(NSArray *)sectionKeys andTitles:(NSDictionary *)sectionTitles
{
    self = [super init];
    if (self) {
        self.responses = responses;
        self.sectionKeys = sectionKeys;
        self.sectionTitles = sectionTitles;
    }

    return self;
}

- (NSArray *)messagesInSection:(NSInteger)section
{
    return [self.responses objectForKey:[self.sectionKeys objectAtIndex:section]];
}

- (MCLResponse *)responseForIndexPath:(NSIndexPath *)indexPath
{
    NSArray *messagesInSection = [self messagesInSection:indexPath.section];
    return messagesInSection[indexPath.row];
}

- (NSArray *)unreadResponses
{
    NSMutableArray *unreadResponses = [NSMutableArray array];
    for (NSString *key in self.responses) {
        for (MCLResponse *response in [self.responses objectForKey:key]) {
            if (!response.isRead) {
                [unreadResponses addObject:response];
            }
        }
    }

    return unreadResponses;
}

- (NSInteger)numberOfUnreadResponses
{
    return [[self unreadResponses] count];
}


@end

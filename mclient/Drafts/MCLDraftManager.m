//
//  MCLDraftManager.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLDraftManager.h"

#import "MCLMessage.h"
#import "MCLDraft.h"


NSString * const MCLDraftsChangedNotification = @"DraftsChangedNotification";
NSString * const MCLDraftsUserDefaultsKey = @"DraftsUserDefaults";

@interface MCLDraftManager ()

@property (strong, nonatomic) NSString *currentKey;
@property (strong, nonatomic) NSMutableDictionary *drafts;
@property (strong, nonatomic) NSUserDefaults *userDefaults;

@end

@implementation MCLDraftManager

- (instancetype)init
{
    self = [super init];
    if (!self) return nil;

    self.userDefaults = [NSUserDefaults standardUserDefaults];
    NSData *data = [self.userDefaults objectForKey:MCLDraftsUserDefaultsKey];
    self.drafts = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if (!self.drafts) { self.drafts = [NSMutableDictionary new]; }

    return self;
}

- (MCLDraft *)current
{
    if (self.currentKey) {
        return self.drafts[self.currentKey];
    }
    return nil;
}

- (NSNumber *)count
{
    return [NSNumber numberWithInteger:[self.all count]];
}

- (NSArray *)all
{
    NSArray *allSorted;
    NSMutableArray *all = [NSMutableArray new];
    for (NSNumber *key in self.drafts) {
        [all addObject:self.drafts[key]];
    }
    allSorted = [all sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSDate *first = [(MCLDraft*)a date];
        NSDate *second = [(MCLDraft*)b date];
        return [second compare:first];
    }];

    return allSorted;
}

- (MCLMessage *)draftForMessage:(MCLMessage *)message
{
    return [MCLMessage messageFromDraft:[self.drafts objectForKey:message.key]];
}

- (void)saveMessageAsDraft:(MCLMessage *)message
{
    [self.drafts setObject:message.draft forKey:message.key];
    self.currentKey = message.key;
    [self persist];

}

- (void)removeDraftForMessage:(MCLMessage *)message
{
    [self.drafts removeObjectForKey:message.key];
    [self persist];
}

- (void)removeCurrent
{
    [self removeDraftForMessage:[MCLMessage messageFromDraft:self.current]];
    self.currentKey = nil;
}

#pragma mark - Private Methods

 - (void)persist
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.drafts];
    [self.userDefaults setObject:data forKey:MCLDraftsUserDefaultsKey];
    [self.userDefaults synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:MCLDraftsChangedNotification object:self];
}

@end

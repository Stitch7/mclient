//
//  MCLMessageResponsesClient.h
//  mclient
//
//  Created by Christopher Reitz on 28/02/2017.
//  Copyright © 2017 Christopher Reitz. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MCLMessageResponsesClientDelegate;

@interface MCLMessageResponsesClient : NSObject

@property (weak) id<MCLMessageResponsesClientDelegate> delegate;

- (void)loadData;

@end

@protocol MCLMessageResponsesClientDelegate <NSObject>

- (void)messageResponsesClient:(MCLMessageResponsesClient *)client foundUnreadResponses:(NSNumber *)numberOfUnreadResponses;
- (void)messageResponsesClient:(MCLMessageResponsesClient *)client fetchedData:(NSMutableDictionary *)responses sectionKeys:(NSMutableArray *)sectionKeys sectionTitles:(NSMutableDictionary *)sectionTitles;
- (void)messageResponsesClient:(MCLMessageResponsesClient *)client failedWithError:(NSError *)error;

@end

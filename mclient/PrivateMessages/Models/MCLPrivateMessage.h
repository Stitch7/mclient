//
//  MCLPrivateMessage.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@interface MCLPrivateMessage : NSObject

@property (strong, nonatomic) NSNumber *messageId;
@property (strong, nonatomic) NSDate *date;
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *subject;
@property (strong, nonatomic) NSString *text;
@property (strong, nonatomic) NSString *type;
@property (assign, nonatomic, getter=isRead) BOOL read;
@property (nonatomic, readonly) NSDictionary *propertyList;

+ (MCLPrivateMessage *)privateMessageFromJSON:(NSDictionary *)json;
+ (MCLPrivateMessage *)privateMessageWithPropertyList:(NSDictionary *)propertyList;


@end

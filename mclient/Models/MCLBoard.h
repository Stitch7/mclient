//
//  MCLBoard.h
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@interface MCLBoard : NSObject

@property (strong, nonatomic) NSNumber *boardId;
@property (strong, nonatomic) NSString *name;

+ (MCLBoard *)boardWithId:(NSNumber *)inBoardId;
+ (MCLBoard *)boardWithId:(NSNumber *)inBoardId name:(NSString *)inName;
+ (MCLBoard *)boardFromJSON:(NSDictionary *)json;
- (UIImage *)image;

@end

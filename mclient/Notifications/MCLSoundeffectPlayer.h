//
//  MCLSoundeffectPlayer.h
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

@interface MCLSoundeffectPlayer : NSObject

+ (void)playCreatedNewPostingSound;
+ (void)playEditedPostingSound;
+ (void)playReloadedSound;
+ (void)playAddThreadToKillfileSound;
+ (void)playRemovedThreadFromKillfileSound;
+ (void)playAddedToFavoritesSound;
+ (void)playRemovedFromFavoritesSound;

@end

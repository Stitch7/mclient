//
//  MCLSoundeffectPlayer.m
//  mclient
//
//  Copyright © 2014 - 2017 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLSoundeffectPlayer.h"

@import AVFoundation;
@import AudioToolbox;

@implementation MCLSoundeffectPlayer

#pragma mark - Private

+ (void)playSoundForResource:(NSString *)resource
{
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"delete" ofType:@"caf"];
    SystemSoundID soundID;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:soundPath], &soundID);
    AudioServicesPlaySystemSound(soundID);
}

#pragma mark - Public

+ (void)playCreatedNewPostingSound
{
    [self playSoundForResource:@""];
}

+ (void)playEditedPostingSound
{
    [self playSoundForResource:@""];
}

+ (void)playReloadedSound
{
    [self playSoundForResource:@""];
}

+ (void)playAddThreadToKillfileSound
{
    [self playSoundForResource:@""];
}

+ (void)playRemovedThreadFromKillfileSound
{
    [self playSoundForResource:@"delete"];
}

+ (void)playAddedToFavoritesSound
{
    [self playSoundForResource:@""];
}

+ (void)playRemovedFromFavoritesSound
{
    [self playSoundForResource:@""];
}

@end

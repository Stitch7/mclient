//
//  constants.h
//  mclient
//
//  Created by Christopher Reitz on 21.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#ifdef DEBUG
//    #define kMServiceBaseURL @"https://reitz.re:8080/mservice"
    #define kMServiceBaseURL @"http://192.168.178.33:8080/mservice"
#else
    #define kMServiceBaseURL @"http://reitz.re:8080/mservice"
#endif

#define kManiacForumURL @"http://www.maniac-forum.de/forum/pxmboard.php"

#define kSettingsSignatureTextDefault @"sent from M!client for iOS"

typedef NS_ENUM(NSUInteger, kMCLSettingsThreadView) {
    kMCLSettingsThreadViewWidmann,
    kMCLSettingsThreadViewFrame
};

typedef NS_ENUM(NSUInteger, kMCLSettingsShowImages) {
    kMCLSettingsShowImagesAlways,
    kMCLSettingsShowImagesWifi,
    kMCLSettingsShowImagesNever
};
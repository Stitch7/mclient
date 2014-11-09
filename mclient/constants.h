//
//  constants.h
//  mclient
//
//  Created by Christopher Reitz on 21.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

//#define kMServiceBaseURL @"http://192.168.178.33:8080/mservice"
#define kMServiceBaseURL @"https://reitz.re:8080/mservice"

#define kManiacForumURL @"http://www.maniac-forum.de/forum/pxmboard.php"

#define kSettingsSignatureTextDefault NSLocalizedString(@"sent from M!client for iOS", nil)

typedef NS_ENUM(NSUInteger, kMCLSettingsThreadView) {
    kMCLSettingsThreadViewWidmann,
    kMCLSettingsThreadViewFrame
};

typedef NS_ENUM(NSUInteger, kMCLSettingsShowImages) {
    kMCLSettingsShowImagesAlways,
    kMCLSettingsShowImagesWifi,
    kMCLSettingsShowImagesNever
};

typedef NS_ENUM(NSUInteger, kMCLComposeType) {
    kMCLComposeTypeThread,
    kMCLComposeTypeReply,
    kMCLComposeTypeEdit
};

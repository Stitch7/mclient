//
//  constants.h
//  mclient
//
//  Created by Christopher Reitz on 21.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#ifdef DEBUG
//    #define kMServiceBaseURL @"http://localhost:8000"
    #define kMServiceBaseURL @"http://reitz.re:8000"
#else
    #define kMServiceBaseURL @"http://reitz.re:8000"
#endif

#define kManiacForumURL @"http://www.maniac-forum.de/forum/pxmboard.php"

typedef NS_ENUM(NSUInteger, kMCLSettingsThreadView) {
    kMCLSettingsThreadViewDefault,
    kMCLSettingsThreadViewFrame
};

typedef NS_ENUM(NSUInteger, kMCLSettingsShowImages) {
    kMCLSettingsShowImagesAlways,
    kMCLSettingsShowImagesWifi,
    kMCLSettingsShowImagesNever
};
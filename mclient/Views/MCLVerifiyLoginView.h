//
//  MCLVerifiyLoginView.h
//  mclient
//
//  Created by Christopher Reitz on 25.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLLoadingView.h"


@interface MCLVerifiyLoginView : MCLLoadingView

- (void)loginStatusWithUsername:(NSString *)username;
- (void)loginStatusNoLogin;

@end

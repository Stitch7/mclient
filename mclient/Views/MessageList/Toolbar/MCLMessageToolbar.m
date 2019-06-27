//
//  MCLMessageToolbar.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLMessageToolbar.h"

#import "MCLMessageToolbarDelegate.h"
#import "MCLLoginManager.h"
#import "MCLUser.h"
#import "MCLBoard.h"
#import "MCLThread.h"
#import "MCLMessage.h"


@implementation MCLMessageToolbar

#pragma mark - Initializers

- (instancetype)init
{
    if (self = [super init]) {
        [self configure];
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self configure];
    }

    return self;
}

- (void)configure
{
    self.translatesAutoresizingMaskIntoConstraints = NO;

    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                            target:nil
                                                                            action:nil];

    UIImage *profileImage = [[UIImage imageNamed:@"profileButton"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.profileButton = [[UIBarButtonItem alloc] initWithImage:profileImage
                                                          style:UIBarButtonItemStylePlain
                                                         target:self
                                                         action:@selector(openProfileAction:)];

    UIImage *copyLinkImage = [[UIImage imageNamed:@"copyLinkButton"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.linkToClipboardButton = [[UIBarButtonItem alloc] initWithImage:copyLinkImage
                                                           style:UIBarButtonItemStylePlain
                                                          target:self
                                                          action:@selector(copyLinkAction:)];

    UIImage *speakImage = [[UIImage imageNamed:@"speakButton"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.speakButton = [[UIBarButtonItem alloc] initWithImage:speakImage
                                                        style:UIBarButtonItemStylePlain
                                                       target:self
                                                       action:@selector(speakAction:)];

    UIImage *notificationImage = [[UIImage imageNamed:@"notificationButton"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.notificationButton = [[UIBarButtonItem alloc] initWithImage:notificationImage
                                                               style:UIBarButtonItemStylePlain
                                                              target:self
                                                              action:@selector(notificationAction:)];

    UIImage *editImage = [[UIImage imageNamed:@"editButton"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.editButton = [[UIBarButtonItem alloc] initWithImage:editImage
                                                       style:UIBarButtonItemStylePlain
                                                      target:self
                                                      action:@selector(editAction:)];

    self.replyButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemReply
                                                                     target:self
                                                                     action:@selector(replyAction:)];

    [self setItems:@[self.profileButton,
                     spacer,
                     self.linkToClipboardButton,
                     spacer,
                     self.speakButton,
                     spacer,
                     self.notificationButton,
                     spacer,
                     self.editButton,
                     spacer,
                     self.replyButton]];
}

#pragma mark - Actions

- (void)openProfileAction:(UIBarButtonItem *)sender
{
    MCLUser *user = [[MCLUser alloc] init];
    user.userId = self.message.userId;
    user.username = self.message.username;
    [self.messageToolbarDelegate messageToolbar:self requestsToOpenProfileFromUser:user];
}

- (void)copyLinkAction:(UIBarButtonItem *)sender
{
    [self.messageToolbarDelegate messageToolbar:self requestsToCopyMessageLinkToClipboard:self.message];
}

- (void)speakAction:(UIBarButtonItem *)sender
{
    [self.messageToolbarDelegate messageToolbar:self requestsToSpeakMessage:self.message];
}

- (void)notificationAction:(UIBarButtonItem *)sender
{
    [self.messageToolbarDelegate messageToolbar:self requestsToToggleNotificationButton:sender
                                     forMessage:self.message
                          withCompletionHandler:nil];
}

- (void)editAction:(UIBarButtonItem *)sender
{
    [self.messageToolbarDelegate messageToolbar:self requestsToEditMessage:self.message];
}

- (void)replyAction:(UIBarButtonItem *)sender
{
    [self.messageToolbarDelegate messageToolbar:self requestsToReplyToMessage:self.message];
}

#pragma mark - Public

- (void)deactivateBarButtons
{
    for (UIBarButtonItem *toolbarButton in self.items) {
        toolbarButton.enabled = NO;
    }
}

- (void)updateBarButtonsWithMessage:(MCLMessage *)message
{
    self.message = message;
    self.nextMessage = message.nextMessage;
    [self updateBarButtons];
}

- (void)updateBarButtons
{
    self.profileButton.enabled = YES;
    self.linkToClipboardButton.enabled = YES;
    self.speakButton.enabled = YES;

    BOOL hideNotificationButton = ![self notificationButtonIsVisible];
    [self hide:hideNotificationButton barButton:self.notificationButton];
    if (!hideNotificationButton) {
        [self enableNotificationButton:self.message.notification];
    }

    BOOL hideEditButton = ![self editButtonIsVisible];
    [self hide:hideEditButton barButton:self.editButton];

    BOOL hideReplyButton = ![self replyButtonIsVisible];
    [self hide:hideReplyButton barButton:self.replyButton];
}

- (void)enableNotificationButton:(BOOL)enable
{
    self.message.notification = enable;

    if (enable) {
        self.notificationButton.tag = 1;
        self.notificationButton.image = [UIImage imageNamed:@"notificationButtonEnabled"];
    } else {
        self.notificationButton.tag = 0;
        self.notificationButton.image = [UIImage imageNamed:@"notificationButtonDisabled"];
    }
}

- (BOOL)notificationButtonIsVisible
{
    return self.loginManager.isLoginValid && [self.message.username isEqualToString:self.loginManager.username];
}

- (BOOL)editButtonIsVisible
{
    return
        !self.message.thread.isClosed &&
        self.loginManager.isLoginValid &&
        [self.message.username isEqualToString:self.loginManager.username] &&
        [self.nextMessage.level compare:self.message.level] != NSOrderedDescending;
}

- (BOOL)replyButtonIsVisible
{
    return self.loginManager.isLoginValid && !self.message.thread.isClosed;
}

#pragma mark - Helper

- (void)hide:(BOOL)hide barButton:(UIBarButtonItem *)barButton
{
    if (hide) {
        [barButton setEnabled:NO];
        [barButton setTintColor:[UIColor clearColor]];
    } else {
        [barButton setEnabled:YES];
        [barButton setTintColor:nil];
    }
}

@end


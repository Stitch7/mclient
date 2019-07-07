//
//  MCLMessageTextViewToolbar.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLMessageTextViewToolbar.h"

#import "MCLMessage.h"
#import "MCLMessageTextViewToolbarDelegate.h"


@implementation MCLMessageTextViewToolbar

#pragma mark - Initializers

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) return nil;

    [self configure];

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (!self) return nil;

    [self configure];

    return self;
}

#pragma mark - Configuration

- (void)configure
{
    UIImage *boldImage = [[UIImage imageNamed:@"boldFilledButton"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIBarButtonItem *boldButton = [[UIBarButtonItem alloc] initWithImage:boldImage
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(boldButtonPressed:)];

    UIImage *italicImage = [[UIImage imageNamed:@"italicFilledButton"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIBarButtonItem *italicButton = [[UIBarButtonItem alloc] initWithImage:italicImage
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(italicButtonPressed:)];

    UIImage *underlineImage = [[UIImage imageNamed:@"underlineFilledButton"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIBarButtonItem *underlineButton = [[UIBarButtonItem alloc] initWithImage:underlineImage
                                                                        style:UIBarButtonItemStylePlain
                                                                       target:self
                                                                       action:@selector(underlineButtonPressed:)];


    UIImage *strikestroughImage = [[UIImage imageNamed:@"strikestroughButton"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIBarButtonItem *strikestroughButton = [[UIBarButtonItem alloc] initWithImage:strikestroughImage
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(strikestroughButtonPressed:)];

    UIBarButtonItem *spoilerButton = [[UIBarButtonItem alloc] initWithTitle:@"Spoiler"
                                                                        style:UIBarButtonItemStylePlain
                                                                       target:self
                                                                       action:@selector(spoilerButtonPressed:)];

    UIImage *cameraImage = [[UIImage imageNamed:@"addImageButton"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIBarButtonItem *cameraButton = [[UIBarButtonItem alloc] initWithImage:cameraImage
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(cameraButtonPressed:)];

    UIImage *quoteImage = [[UIImage imageNamed:@"quoteButton"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIBarButtonItem *quoteButton = [[UIBarButtonItem alloc] initWithImage:quoteImage
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(quoteButtonPressed:)];
    quoteButton.imageInsets = UIEdgeInsetsMake(0.0, +15, 0, 0);

    UIBarButtonItem *fixedSpacer = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                                target:nil
                                                                                action:nil];

    UIBarButtonItem *flexibleSpacer = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil
                                                                                   action:nil];

    NSMutableArray *toolbarItems = [[NSMutableArray alloc] init];

    [toolbarItems addObject:boldButton];
    [toolbarItems addObject:fixedSpacer];
    [toolbarItems addObject:italicButton];
    [toolbarItems addObject:fixedSpacer];
    [toolbarItems addObject:underlineButton];
    [toolbarItems addObject:fixedSpacer];
    [toolbarItems addObject:strikestroughButton];
    [toolbarItems addObject:fixedSpacer];
    [toolbarItems addObject:spoilerButton];
    [toolbarItems addObject:flexibleSpacer];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
        [toolbarItems addObject:cameraButton];
    }
    [toolbarItems addObject:fixedSpacer];
    [toolbarItems addObject:quoteButton];
    
    self.barStyle = UIBarStyleBlackTranslucent;
    self.items = toolbarItems;
    [self sizeToFit];
}

- (void)setType:(NSUInteger)type
{
    if (type != kMCLComposeTypeReply) {
        NSMutableArray *toolbarItems = [self.items mutableCopy];
        [toolbarItems removeLastObject];
        [self setItems:toolbarItems animated:NO];
    }
}

- (void)boldButtonPressed:(UIBarButtonItem *)sender
{
    [self.messageTextViewToolbarDelegate messageTextViewToolbar:self boldButtonPressed:sender];
}

- (void)italicButtonPressed:(UIBarButtonItem *)sender
{
    [self.messageTextViewToolbarDelegate messageTextViewToolbar:self italicButtonPressed:sender];
}

- (void)underlineButtonPressed:(UIBarButtonItem *)sender
{
    [self.messageTextViewToolbarDelegate messageTextViewToolbar:self underlineButtonPressed:sender];
}

- (void)strikestroughButtonPressed:(UIBarButtonItem *)sender
{
    [self.messageTextViewToolbarDelegate messageTextViewToolbar:self strikestroughButtonPressed:sender];
}

- (void)spoilerButtonPressed:(UIBarButtonItem *)sender
{
    [self.messageTextViewToolbarDelegate messageTextViewToolbar:self spoilerButtonPressed:sender];
}

- (void)quoteButtonPressed:(UIBarButtonItem *)sender
{
    [self.messageTextViewToolbarDelegate messageTextViewToolbar:self quoteButtonPressed:sender];
}

- (void)cameraButtonPressed:(UIBarButtonItem *)sender
{
    [self.messageTextViewToolbarDelegate messageTextViewToolbar:self cameraButtonPressed:sender];
}

@end

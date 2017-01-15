//
//  MCLMessageListViewController.m
//  mclient
//
//  Created by Christopher Reitz on 19.09.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLMessageListViewController.h"

#import "utils.h"
#import "UIColor+Hex.h"
#import "MCLThread.h"
#import "MCLBoard.h"
#import "MCLThemeManager.h"

@implementation MCLMessageListViewController

@synthesize splitViewButton = _splitViewButton;

+ (NSString *)messageHtmlSkeletonForHtml:(NSString *)html withTopMargin:(int)topMargin andTheme:(id <MCLTheme>)currentTheme
{
    NSInteger fontSizeValue = [[NSUserDefaults standardUserDefaults] integerForKey:@"fontSize"];
    NSString *fontSize = [NSString stringWithFormat:@"%lipx", fontSizeValue + 11];
    NSString *textColor = [currentTheme isDark] ? @"#fff" : @"#000";
    NSString *linkColor = [[currentTheme tintColor] cssString];

    return [NSString stringWithFormat:@""
            "<html>"
            "<head>"
            "<meta name=\"viewport\" content=\"initial-scale=1.0\"/>"
            "<script type=\"text/javascript\">"
            "    function spoiler(obj) {"
            "        if (obj.nextSibling.style.display === 'none') {"
            "            obj.nextSibling.style.display = 'inline';"
            "        } else {"
            "            obj.nextSibling.style.display = 'none';"
            "        }"
            "    }"
            "</script>"
            "<style>"
            "    * {"
            "        font-family: \"Helvetica Neue\";"
            "        font-size: %@;"
            "        -webkit-text-size-adjust: none;"
            "    }"
            "    body {"
            "        margin: %ipx 20px 10px 20px;"
            "        padding: 0px;"
            "        background-color: transparent;"
            "        color: %@;"
            "    }"
            "    a {"
            "        word-break: break-all;"
            "        color: %@;"
            "    }"
            "    img {"
            "        max-width: 100%%;"
            "    }"
            "    button > img {"
            "        content:url(\"http://www.maniac-forum.de/forum/images/spoiler.png\");"
            "        width: 17px;"
            "    }"
            "</style>"
            "</head>"
            "<body>%@</body>"
            "</html>", fontSize, topMargin, textColor, linkColor, html];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.currentTheme = [[MCLThemeManager sharedManager] currentTheme];
    [self configureTitle];
}

- (void)configureTitle
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 480, 44)];
    label.backgroundColor = [UIColor clearColor];
    label.numberOfLines = 2;
    label.font = [UIFont boldSystemFontOfSize: 15.0f];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [self.currentTheme navigationBarTextColor];
    label.text = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];

    self.titleLabel = label;
    self.navigationItem.titleView = label;
}

- (void)updateTitle:(NSString *)title
{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:title];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 0.5;
    paragraphStyle.hyphenationFactor = 1.0;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, title.length)];
    self.titleLabel.attributedText = attributedString;
}

# pragma mark - Abstract

- (void)loadThread:(MCLThread *)inThread fromBoard:(MCLBoard *)inBoard
{
    mustOverride();
}

#pragma mark - SplitViewButtonHandler

-(void) turnSplitViewButtonOn: (UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *) popoverController
{
    NSString *activeDetailViewControllerClassName = NSStringFromClass([[[[self.splitViewController.viewControllers lastObject] viewControllers] firstObject] class]);

    NSString *barButtonTitle = NSLocalizedString(@"Threads", nil);
    if ([activeDetailViewControllerClassName isEqualToString:@"MCLMessageListViewController"]) {
        barButtonTitle = NSLocalizedString(@"Boards", nil);
    }
    barButtonItem.title = barButtonTitle;
    _splitViewButton = barButtonItem;

    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

-(void)turnSplitViewButtonOff {
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    _splitViewButton = nil;
    self.masterPopoverController = nil;
}

-(void) setSplitViewButton:(UIBarButtonItem *)splitViewButton forPopoverController:(UIPopoverController *)popoverController {
    if (splitViewButton != _splitViewButton) {
        if (splitViewButton) {
            [self turnSplitViewButtonOn:splitViewButton forPopoverController:popoverController];
        } else {
            [self turnSplitViewButtonOff];
        }
    }
}

@end

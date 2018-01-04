//
//  MCLSplitViewController.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLSplitViewController.h"

#import "MCLDependencyBag.h"
#import "MCLThemeManager.h"
#import "MCLTheme.h"

@interface MCLSplitViewController ()

@property (strong, nonatomic) id <MCLDependencyBag> bag;

@end

@implementation MCLSplitViewController

#pragma mark - Initializers

- (instancetype)initWithBag:(id <MCLDependencyBag>)bag
{
    self = [super init];
    if (!self) return nil;

    self.bag = bag;

    return self;
}

#pragma mark - UISplitViewController overrides

- (void)viewDidLoad
{
    self.maximumPrimaryColumnWidth = 350;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return [self.bag.themeManager.currentTheme isDark]
        ? UIStatusBarStyleLightContent
        : UIStatusBarStyleDefault;
}

//- (BOOL)canBecomeFirstResponder
//{
//    return YES;
//}

//- (NSArray<UIKeyCommand *>*)keyCommands
//{
//    return @[
//
//             [UIKeyCommand keyCommandWithInput:@"\b"
//                                 modifierFlags:kNilOptions
//                                        action:@selector(selectTab:)
//                          discoverabilityTitle:@"Zurück"],
//             [UIKeyCommand keyCommandWithInput:@"n"
//                                 modifierFlags:UIKeyModifierCommand
//                                        action:@selector(selectTab:)
//                          discoverabilityTitle:@"Neuer Thread"],
//             [UIKeyCommand keyCommandWithInput:@"r"
//                                 modifierFlags:UIKeyModifierCommand
//                                        action:@selector(selectTab:)
//                          discoverabilityTitle:@"Auf Posting antworten"],
//             [UIKeyCommand keyCommandWithInput:@"u"
//                                 modifierFlags:UIKeyModifierCommand
//                                        action:@selector(selectTab:)
//                          discoverabilityTitle:@"User Profil öffnen"],
//
//
//
//             [UIKeyCommand keyCommandWithInput:UIKeyInputRightArrow
//                                 modifierFlags:kNilOptions
//                                        action:@selector(selectTab:)
//                          discoverabilityTitle:@"Nächstes Posting laden"],
//             [UIKeyCommand keyCommandWithInput:UIKeyInputLeftArrow
//                                 modifierFlags:kNilOptions
//                                        action:@selector(selectTab:)
//                          discoverabilityTitle:@"Vorheriges Posting laden"],
//             [UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow
//                                 modifierFlags:kNilOptions
//                                        action:@selector(selectTab:)
//                          discoverabilityTitle:@"Nächsten Thread laden"],
//             [UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow
//                                 modifierFlags:kNilOptions
//                                        action:@selector(selectTab:)
//                          discoverabilityTitle:@"Vorherigen Thread laden"],
//
//             ];
//}

//- (void)selectTab:(UIKeyCommand *)sender
//{
//    NSString *selectedTab = sender.input;
//    // ...
//}

@end

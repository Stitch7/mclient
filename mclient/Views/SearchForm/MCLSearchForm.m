//
//  MCLSearchFormView.m
//  mclient
//
//  Copyright © 2014 - 2018 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLSearchFormView.h"

@implementation MCLSearchFormView

- (instancetype)init
{
    self = [super initWithFrame:CGRectNull];
    if (!self) return nil;

    [self configureSubviews];

    return self;
}

- (void)configureSubviews
{
    self.phraseTextField.placeholder = @"Suchbegriff"; // TODO: i18n
    self.autorTextField.placeholder = @"Autor"; // TODO: i18n
    self.searchInBodyLabel.text = @"Nachrichtentext durchsuchen"; // TODO: i18n
    self.searchInSubjectLabel.text = @"Betreff durchsuchen"; // TODO: i18n
    self.boardTextField.placeholder = @"Board"; // TODO: i18n
    self.daysTextField.placeholder = @"Zeitraum"; // TODO: i18n
    [self.searchButton setTitle:@"SUCHEN" forState:UIControlStateNormal]; // TODO: i18n
}

@end

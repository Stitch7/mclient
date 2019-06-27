//
//  MCLDraftTableViewCell.m
//  mclient
//
//  Copyright © 2014 - 2019 Christopher Reitz. Licensed under the MIT license.
//  See LICENSE file in the project root for full license information.
//

#import "MCLDraftTableViewCell.h"

#import "MCLDependencyBag.h"
#import "MCLRouter+mainNavigation.h"
#import "MCLTheme.h"
#import "MCLThemeManager.h"
#import "MCLDraft.h"
#import "MCLBoard.h"
#import "MCLMessage.h"

NSString *const MCLDraftTableViewCellIdentifier = @"DraftCell";

@interface MCLDraftTableViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *typeImageView;
@property (weak, nonatomic) IBOutlet UIImageView *arrowImageView;
@property (weak, nonatomic) IBOutlet UILabel *typeLabel;
@property (weak, nonatomic) IBOutlet UIButton *originalSubjectButton;
@property (weak, nonatomic) IBOutlet UILabel *subjectLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageTextLabel;

@end

@implementation MCLDraftTableViewCell

- (void)setBag:(id<MCLDependencyBag>)bag
{
    _bag = bag;

    UIView *backgroundView = [[UIView alloc] initWithFrame:self.frame];
    backgroundView.backgroundColor = [self.bag.themeManager.currentTheme tableViewCellSelectedBackgroundColor];
    self.selectedBackgroundView = backgroundView;
}

- (void)setDraft:(MCLDraft *)draft
{
    _draft = draft;

    id<MCLTheme> currentTheme = self.bag.themeManager.currentTheme;

    UIImage *image = draft.type == kMCLComposeTypeThread
        ? [UIImage imageNamed:@"createThreadButtonSmall"]
        : [UIImage imageNamed:@"replyButtonSmall"];
    self.typeImageView.image = image;
    self.typeImageView.image = [self.typeImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.typeImageView.tintColor = [currentTheme textColor];
    self.typeImageView.layoutMargins = UIEdgeInsetsMake(0, 0, 0, 100);

    self.typeLabel.text = draft.type == kMCLComposeTypeThread
        ? NSLocalizedString(@"draft_cell_type_thread", nil)
        : NSLocalizedString(@"draft_cell_type_reply", nil);

    NSString *originalSubjectButtonTitle;
    if (draft.type == kMCLComposeTypeThread) {
        originalSubjectButtonTitle = draft.boardName;
    } else {
        originalSubjectButtonTitle = draft.originalSubject;
    }

    [self.originalSubjectButton setTitle:originalSubjectButtonTitle forState:UIControlStateNormal];
    self.originalSubjectButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    self.originalSubjectButton.contentEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 0);
    [self.originalSubjectButton addTarget:self action:@selector(originalSubjectButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    self.arrowImageView.image = [self.arrowImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.arrowImageView.tintColor = [currentTheme tintColor];

    self.subjectLabel.text = draft.subject;

    NSString *text = draft.text;
    NSUInteger maxTextLength = 200;
    if (text.length > maxTextLength) {
        text = [[text substringToIndex:maxTextLength] stringByAppendingString:@"..."];
    }

    NSString *editLabel = NSLocalizedString(@"draft_cell_edit", nil);
    NSDictionary *attr = @{NSFontAttributeName:[UIFont systemFontOfSize:13],
                           NSForegroundColorAttributeName:[currentTheme textColor]};
    NSMutableAttributedString *attrText = [[NSMutableAttributedString alloc] initWithString:text attributes:attr];
    NSDictionary *editLabelAttr = @{NSFontAttributeName:[UIFont systemFontOfSize:13],
                           NSForegroundColorAttributeName:[currentTheme tintColor]};
    [attrText appendAttributedString:[[NSAttributedString alloc] initWithString:[@"  " stringByAppendingString:editLabel]
                                                            attributes:editLabelAttr]];
    self.messageTextLabel.textColor = nil; // without it takes the color from UIAppearance proxy for whatever reason
    self.messageTextLabel.attributedText = attrText;
}

- (void)originalSubjectButtonPressed:(UIButton *)sender
{
    if (self.draft.type == kMCLComposeTypeThread) {
        MCLBoard *board = [MCLBoard boardWithId:self.draft.boardId name:self.draft.boardName];
        [self.bag.router pushToThreadListFromBoard:board];
    } else {
        MCLMessage *message = [MCLMessage messageFromDraft:self.draft];
        [self.bag.router pushToMessage:message];
    }
}

@end

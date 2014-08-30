//
//  MCLThreadTableViewCell.m
//  mclient
//
//  Created by Christopher Reitz on 26.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLThreadTableViewCell.h"
#import "MCLReadSymbolView.h"

@implementation MCLThreadTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
//        self.readSymbol = [[MCLReadSymbolView alloc] initWithFrame:CGRectZero];
//        NSLog(@"Huhu");
    }
    return self;
    
    
//    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
//        self.readSymbol = [[MCLReadSymbolView alloc] initWithFrame:CGRectZero];
//        NSLog(@"Huhu");
//    }
//    
//    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

//- (void)layoutSubviews
//{
//	[super layoutSubviews];
//    
//    
//
//    CGRect rect = CGRectMake(5, 15, 10, 10); 
//    self.readSymbol = [[MCLReadSymbolView alloc] initWithFrame:rect];
//    [self.contentView addSubview:self.readSymbol];
//    
////    self.readSymbol.hidden = YES;
//    
////    NSLog(@"layoutSubviews: %@", self.readSymbol);
//    
//
//}

- (void)markRead
{
    self.readSymbolView.hidden = YES;
    
    
    
//    NSLog(@"markRead1: %@", self.readSymbol);
//    self.readSymbol.hidden = YES;
    
//    self.readSymbol.hidden = NO;
    
//    [self.readSymbol removeFromSuperview];
    
//    for (id subview in self.contentView.subviews) {
//        if ([[subview class] isSubclassOfClass: [MCLReadSymbolView class]]) {
////            [subview setHidden:YES];
//            NSLog(@"subview: %@", subview);
//        }
//    }

    
    
//    NSLog(@"markRead2: %@", self.readSymbol);
}

- (void)markUnread
{
    self.readSymbolView.hidden = NO;
}

@end

//
//  MCLAddThreadTableViewController.m
//  mclient
//
//  Created by Christopher Reitz on 31.08.14.
//  Copyright (c) 2014 Christopher Reitz. All rights reserved.
//

#import "MCLAddThreadTableViewController.h"

@interface MCLAddThreadTableViewController ()

@property (weak, nonatomic) IBOutlet UITextField *threadSubjectTextField;
@property (weak, nonatomic) IBOutlet UITextView *threadTextTextField;

@end

@implementation MCLAddThreadTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    if (self = [super initWithStyle:style]) {
        // Custom initialization
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    
    self.threadSubjectTextField.delegate = self;
    [self.threadSubjectTextField becomeFirstResponder];
    
//    self.threadTextTextField.layer.borderWidth = 0.5f;

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.threadSubjectTextField) {
        [textField resignFirstResponder];
        [self.threadTextTextField becomeFirstResponder];
    }
    
    return NO;
}


#pragma mark - Actions

- (IBAction)cancelAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)saveAction:(id)sender {
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

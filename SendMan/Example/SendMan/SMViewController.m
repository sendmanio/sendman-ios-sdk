//
//  SMViewController.m
//  SendMan
//
//  Created by anatha on 12/22/2019.
//  Copyright (c) 2019 anatha. All rights reserved.
//

#import "SMViewController.h"
#import <SendMan/Sendman.h>

@interface SMViewController ()

@end

@implementation SMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)quicheDismiss:(id)sender {
    [Sendman addUserEvent:@"Screen dismissed" stringValue:@"Broccoli Quiche"];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)risottoDismiss:(id)sender {
    [Sendman addUserEvent:@"Screen dismissed" stringValue:@"Risotto"];
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)recipesDismiss:(id)sender {
    [Sendman addUserEvent:@"Screen dismissed" stringValue:@"Recipes"];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)risottoSelected:(id)sender {
    [Sendman addUserEvent:@"Recipe clicked" numberValue:[NSNumber numberWithInt:1]];
}

- (IBAction)quicheSelected:(id)sender {
    [Sendman addUserEvent:@"Recipe clicked" numberValue:[NSNumber numberWithInt:2]];
}

- (IBAction)flowStarted:(id)sender {
    [Sendman addUserEvent:@"Recipe clicked"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

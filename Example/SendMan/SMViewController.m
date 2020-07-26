//
//  SMViewController.m
//  SendMan
//
//  Created by anatha on 12/22/2019.
//  Copyright (c) 2019 anatha. All rights reserved.
//

#import "SMViewController.h"
#import <SendMan/SendMan.h>
#import <SendMan/SMNotificationsViewController.h>

@interface SMViewController ()

@end

@implementation SMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)quicheDismiss:(id)sender {
    [SendMan addUserEvent:@"Screen dismissed" stringValue:@"Broccoli Quiche"];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)risottoDismiss:(id)sender {
    [SendMan addUserEvent:@"Screen dismissed" stringValue:@"Risotto"];
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)recipesDismiss:(id)sender {
    [SendMan addUserEvent:@"Screen dismissed" stringValue:@"Recipes"];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)risottoSelected:(id)sender {
    [SendMan addUserEvent:@"Recipe clicked" numberValue:[NSNumber numberWithInt:1]];
}

- (IBAction)quicheSelected:(id)sender {
    [SendMan addUserEvent:@"Recipe clicked" numberValue:[NSNumber numberWithInt:2]];
}

- (IBAction)flowStarted:(id)sender {
    [SendMan addUserEvent:@"Recipe clicked"];
}
- (IBAction)navigationToNotificationsPage:(id)sender {
    [self presentViewController:[SendMan getCategoriesUIViewController] animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

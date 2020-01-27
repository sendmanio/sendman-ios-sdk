//
//  MSViewController.m
//  MarketSend
//
//  Created by anatha on 12/22/2019.
//  Copyright (c) 2019 anatha. All rights reserved.
//

#import "MSViewController.h"
#import <MarketSend/MSDataCollector.h>

@interface MSViewController ()

@end

@implementation MSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)quicheDismiss:(id)sender {
    [MSDataCollector addUserEvent:@"Screen dismissed" stringValue:@"Broccoli Quiche"];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)risottoDismiss:(id)sender {
    [MSDataCollector addUserEvent:@"Screen dismissed" stringValue:@"Risotto"];
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)recipesDismiss:(id)sender {
    [MSDataCollector addUserEvent:@"Screen dismissed" stringValue:@"Recipes"];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)risottoSelected:(id)sender {
    [MSDataCollector addUserEvent:@"Recipe clicked" numberValue:[NSNumber numberWithInt:1]];
}

- (IBAction)quicheSelected:(id)sender {
    [MSDataCollector addUserEvent:@"Recipe clicked" numberValue:[NSNumber numberWithInt:2]];
}

- (IBAction)flowStarted:(id)sender {
    [MSDataCollector addUserEvent:@"Recipe clicked"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

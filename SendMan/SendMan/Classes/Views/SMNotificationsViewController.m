//
//  SMNotificationsViewController.m
//  SendMan
//
//  Created by Anat Sheba Harari on 22/03/2020.
//

#import "SMNotificationsViewController.h"
#import "SMNotificationTableViewCell.h"
#import "SMNotificationsHeaderCell.h"
#import "SMNotificationsFooterCell.h"
#import <SendMan/SendMan.h>

#define SM_NOTIFICATION_CELL_IDENTIFIER @"SMNotificationTableViewCell"
#define SM_NOTIFICATION_HEADER_IDENTIFIER @"SMNotificationsHeaderCell"
#define SM_NOTIFICATION_FOOTER_IDENTIFIER @"SMNotificationsFooterCell"

#define SM_NOTIFICATION_GREY_COLOR [UIColor colorWithRed:0.94 green:0.94 blue:0.96 alpha:1.00]; //#F0F0F6


@interface SMNotificationsViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation SMNotificationsViewController

NSArray *tableData;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.backgroundColor = SM_NOTIFICATION_GREY_COLOR;
    
    tableData = [Sendman getCategories];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [Sendman updateUserCategories:tableData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numRows = [[tableData objectAtIndex:section][@"categories"] count];
    return numRows > 0 ? numRows : 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [tableData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SMNotificationTableViewCell *cell = (SMNotificationTableViewCell *)[tableView dequeueReusableCellWithIdentifier:SM_NOTIFICATION_CELL_IDENTIFIER];
    cell.delegate = self;
    
    NSDictionary *categoryGroup = [tableData objectAtIndex:indexPath.section];
    NSArray *categories = [categoryGroup objectForKey:@"categories"];
    
    NSDictionary *category;
    if (!categories) {
        category = categoryGroup;
    } else {
        category = [categories objectAtIndex:indexPath.row];
    }
    
    [cell setData:category forIndexPath:indexPath];
    
    //    [cell.categorySwitch setOnTintColor:[UIColor systemBlueColor]];
    
    return cell;
}

-(CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section {
    return [self calcHeaderFooterHeightForSection:section];
}

-(CGFloat)tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section {
    return [self calcHeaderFooterHeightForSection:section];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    SMNotificationsHeaderCell *sectionCell = [tableView dequeueReusableCellWithIdentifier:SM_NOTIFICATION_HEADER_IDENTIFIER];
    
    NSDictionary *categoryGroup = [tableData objectAtIndex:section];
    sectionCell.title.text = [[categoryGroup objectForKey:@"name"] uppercaseString];
    
    sectionCell.contentView.backgroundColor = SM_NOTIFICATION_GREY_COLOR;
    return sectionCell.contentView;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    SMNotificationsFooterCell *sectionCell = [tableView dequeueReusableCellWithIdentifier:SM_NOTIFICATION_FOOTER_IDENTIFIER];
    
    NSDictionary *categoryGroup = [tableData objectAtIndex:section];
    sectionCell.subtitle.text = [categoryGroup objectForKey:@"description"];
    
    sectionCell.contentView.backgroundColor = SM_NOTIFICATION_GREY_COLOR;
    return sectionCell.contentView;
}

- (void)categoryValueChangedForIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *categoryGroup = [tableData objectAtIndex:indexPath.section];
    NSArray *categories = [categoryGroup objectForKey:@"categories"];
    NSDictionary *category;
    if (!categories) {
        category = categoryGroup;
    } else {
        category = [categories objectAtIndex:indexPath.row];
    }
    
    NSNumber *newValue = [[category objectForKey:@"value"] boolValue] ? @NO : @YES;
    [category setValue:newValue forKey:@"value"];
}

- (CGFloat) calcHeaderFooterHeightForSection:(NSInteger)section {
    NSDictionary *categoryGroup = [tableData objectAtIndex:section];
    if ([categoryGroup objectForKey:@"categories"] == nil) {
        return 0;
    }
    return UITableViewAutomaticDimension;
}

@end

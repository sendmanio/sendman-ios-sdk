//
//  SMNotificationsViewController.m
//  Copyright © 2020 SendMan Inc. (https://sendman.io/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "SMNotificationsViewController.h"
#import "SMNotificationTableViewCell.h"
#import "SMNotificationsHeaderCell.h"
#import "SMNotificationsFooterCell.h"
#import "SendMan.h"
#import "SMCategoriesHandler.h"
#import "SMDataCollector.h"
#import "SMCategory.h"

#define SM_NOTIFICATION_CELL_IDENTIFIER @"SMNotificationTableViewCell"
#define SM_NOTIFICATION_HEADER_IDENTIFIER @"SMNotificationsHeaderCell"
#define SM_NOTIFICATION_FOOTER_IDENTIFIER @"SMNotificationsFooterCell"

#define SM_NOTIFICATION_GREY_COLOR [UIColor colorWithRed:0.94 green:0.94 blue:0.96 alpha:1.00]; //#F0F0F6
#define SM_NOTIFICATION_GREY_TEXT_COLOR [UIColor colorWithRed: 0.44 green: 0.44 blue: 0.46 alpha: 1.00]; //#707075


@interface SMNotificationsViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIView *backgroundView;

@end

@implementation SMNotificationsViewController

NSArray *tableData;

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        self.backgroundColor = SM_NOTIFICATION_GREY_COLOR;
        self.switchBackgroundColor = SM_NOTIFICATION_GREY_COLOR;
        self.switchOnTintColor = [UIColor systemGreenColor];
        self.switchThumbColor = [UIColor whiteColor];
        self.cellBackgroundColor = [UIColor whiteColor];
        self.titleColor = SM_NOTIFICATION_GREY_TEXT_COLOR;
        self.descriptionColor = SM_NOTIFICATION_GREY_TEXT_COLOR;
        self.textColor = [UIColor blackColor];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.backgroundColor = self.backgroundColor;
    self.backgroundView.backgroundColor = self.backgroundColor;
    
    self.tableView.sectionHeaderHeight =  UITableViewAutomaticDimension;
    self.tableView.estimatedSectionHeaderHeight = 25;
    self.tableView.sectionFooterHeight =  UITableViewAutomaticDimension;
    self.tableView.estimatedSectionFooterHeight = 25;

    tableData = [SendMan getCategories];
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(categoriesRetrieved) name:CategoriesRetrievedNotification object:nil];
    [SMDataCollector addSdkEventWithName:@"User viewed categories" andValue:nil];
    [SMCategoriesHandler getCategories];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [SMCategoriesHandler updateCategories:tableData];
}

- (void)categoriesRetrieved {
    dispatch_async(dispatch_get_main_queue(), ^{
        tableData = [SendMan getCategories];
        [self.tableView reloadData];
    });
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    SMCategory *categoryGroup = [tableData objectAtIndex:section];
    BOOL isGroup = categoryGroup.defaultValue == nil;
    if (isGroup) {
        return [categoryGroup.categories count];
    }
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [tableData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SMNotificationTableViewCell *cell = (SMNotificationTableViewCell *)[tableView dequeueReusableCellWithIdentifier:SM_NOTIFICATION_CELL_IDENTIFIER];
    cell.delegate = self;
    
    SMCategory *categoryGroup = [tableData objectAtIndex:indexPath.section];
    NSArray<SMCategory *> *categories = categoryGroup.categories;
    
    SMCategory *category;
    if (!categories) {
        category = categoryGroup;
    } else {
        category = [categories objectAtIndex:indexPath.row];
    }
    
    [cell setData:category forIndexPath:indexPath];
    
    cell.backgroundColor = self.cellBackgroundColor;
    cell.categoryName.textColor = self.textColor;
    cell.categoryDescription.textColor = self.descriptionColor;
    cell.categorySwitch.onTintColor = self.switchOnTintColor;
    cell.categorySwitch.thumbTintColor = self.switchThumbColor;
    cell.categorySwitch.backgroundColor = self.switchBackgroundColor;
    cell.categorySwitch.layer.cornerRadius = 16;
    
    
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
    
    SMCategory *categoryGroup = [tableData objectAtIndex:section];
    sectionCell.title.text = [categoryGroup.name uppercaseString];
    sectionCell.title.textColor = self.titleColor;
    
    sectionCell.contentView.backgroundColor = self.backgroundColor;
    return sectionCell.contentView;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    SMNotificationsFooterCell *sectionCell = [tableView dequeueReusableCellWithIdentifier:SM_NOTIFICATION_FOOTER_IDENTIFIER];
    
    SMCategory *categoryGroup = [tableData objectAtIndex:section];
    sectionCell.subtitle.text = categoryGroup.categoryDescription;
    sectionCell.subtitle.textColor = self.descriptionColor;
    
    sectionCell.contentView.backgroundColor = self.backgroundColor;
    return sectionCell.contentView;
}

- (void)categoryValueChangedForIndexPath:(NSIndexPath *)indexPath {
    SMCategory *categoryGroup = [tableData objectAtIndex:indexPath.section];
    NSArray<SMCategory *> *categories = categoryGroup.categories;
    SMCategory *category;
    if (!categories) {
        category = categoryGroup;
    } else {
        category = [categories objectAtIndex:indexPath.row];
    }
    
    BOOL oldValue = [category.value boolValue];
    NSNumber *newValue = oldValue ? @NO : @YES;
    [SMDataCollector addSdkEventWithName:oldValue ? @"Category toggled off" : @"Category toggled on" andValue:category.id];
    category.value = newValue;
}

- (CGFloat) calcHeaderFooterHeightForSection:(NSInteger)section {
    SMCategory *categoryGroup = [tableData objectAtIndex:section];
    if (categoryGroup.categories == nil) {
        return 0;
    }
    return UITableViewAutomaticDimension;
}

@end

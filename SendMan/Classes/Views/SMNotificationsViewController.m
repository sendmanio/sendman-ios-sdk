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
#import "Sendman.h"
#import "SMCategoriesHandler.h"

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
        self.backgroundView.backgroundColor = SM_NOTIFICATION_GREY_COLOR;
        self.backgroundColor = SM_NOTIFICATION_GREY_COLOR;
        self.switchBackgroundColor = SM_NOTIFICATION_GREY_COLOR;
        self.switchOnTintColor = [UIColor systemGreenColor];
        self.switchThumbColor = [UIColor whiteColor];
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
    
    tableData = [Sendman getCategories];
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(categoriesRetrieved) name:CategoriesRetrievedNotification object:nil];
    [SMCategoriesHandler getCategories];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [Sendman updateUserCategories:tableData];
}

- (void)categoriesRetrieved {
    tableData = [Sendman getCategories];
    dispatch_async(dispatch_get_main_queue(), ^{
         [self.tableView reloadData];
    });
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *categoryGroup = [tableData objectAtIndex:section];
    BOOL isGroup = [categoryGroup[@"defaultValue"] isKindOfClass:[NSNull class]];
    if (isGroup) {
        return [categoryGroup[@"categories"] count];
    }
    return 1;
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
    
    NSDictionary *categoryGroup = [tableData objectAtIndex:section];
    sectionCell.title.text = [[categoryGroup objectForKey:@"name"] uppercaseString];
    sectionCell.title.textColor = self.titleColor;
    
    sectionCell.contentView.backgroundColor = self.backgroundColor;
    return sectionCell.contentView;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    SMNotificationsFooterCell *sectionCell = [tableView dequeueReusableCellWithIdentifier:SM_NOTIFICATION_FOOTER_IDENTIFIER];
    
    NSDictionary *categoryGroup = [tableData objectAtIndex:section];
    sectionCell.subtitle.text = [categoryGroup objectForKey:@"description"];
    sectionCell.subtitle.textColor = self.descriptionColor;
    
    sectionCell.contentView.backgroundColor = self.backgroundColor;
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
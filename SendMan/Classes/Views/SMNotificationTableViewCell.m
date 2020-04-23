//
//  SMNotificationTableViewCell.m
//  SendMan
//
//  Created by Anat Sheba Harari on 22/03/2020.
//

#import "SMNotificationTableViewCell.h"

@interface SMNotificationTableViewCell ()

@property (strong, nonatomic) NSIndexPath *indexPath;

@end

@implementation SMNotificationTableViewCell

-(void)setData:(NSDictionary *)category forIndexPath:(NSIndexPath *)indexPath {
    self.indexPath = indexPath;
    
    self.categoryName.text = [category objectForKey:@"name"];
    self.categoryDescription.text = [category objectForKey:@"description"];
    self.categorySwitch.on = [[category objectForKey:@"value"] boolValue];
}

- (IBAction)valueChanged:(id)sender {
    [self.delegate categoryValueChangedForIndexPath:self.indexPath];
}
@end

//
//  SMNotificationTableViewCell.h
//  SendMan
//
//  Created by Anat Sheba Harari on 22/03/2020.
//

#import <UIKit/UIKit.h>
#import "SMNotificationCellDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface SMNotificationTableViewCell : UITableViewCell

-(void)setData:(NSDictionary *)category forIndexPath:(NSIndexPath *)indexPath;

@property (nonatomic, weak) id<SMNotificationCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet UILabel *categoryName;
@property (weak, nonatomic) IBOutlet UILabel *categoryDescription;
@property (weak, nonatomic) IBOutlet UISwitch *categorySwitch;

@end

NS_ASSUME_NONNULL_END

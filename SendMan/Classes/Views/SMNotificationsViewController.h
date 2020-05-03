//
//  SMNotificationsViewController.h
//  SendMan
//
//  Created by Anat Sheba Harari on 22/03/2020.
//

#import <UIKit/UIKit.h>
#import "SMNotificationCellDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface SMNotificationsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, SMNotificationCellDelegate>

@property (strong, nonatomic, nonnull) UIColor *backgroundColor;
@property (strong, nonatomic, nonnull) UIColor *switchBackgroundColor;
@property (strong, nonatomic, nonnull) UIColor *switchOnTintColor;
@property (strong, nonatomic, nonnull) UIColor *switchThumbColor;
@property (strong, nonatomic, nonnull) UIColor *titleColor;
@property (strong, nonatomic, nonnull) UIColor *descriptionColor;
@property (strong, nonatomic, nonnull) UIColor *textColor;

@end

NS_ASSUME_NONNULL_END

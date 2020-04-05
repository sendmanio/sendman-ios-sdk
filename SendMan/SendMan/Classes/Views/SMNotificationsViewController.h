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

@end

NS_ASSUME_NONNULL_END

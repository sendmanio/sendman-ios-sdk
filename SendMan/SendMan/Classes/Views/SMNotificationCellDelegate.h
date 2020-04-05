//
//  SMNotificationCellDelegate.h
//  SendMan
//
//  Created by Anat Sheba Harari on 05/04/2020.
//

#import <Foundation/Foundation.h>

@protocol SMNotificationCellDelegate <NSObject>

@required
- (void)categoryValueChangedForIndexPath:(NSIndexPath *)indexPath;

@end


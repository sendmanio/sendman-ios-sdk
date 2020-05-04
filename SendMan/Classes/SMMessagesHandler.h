//
//  SMMessagesHandler.h
//  SendMan
//
//  Created by Anat Sheba Harari on 30/03/2020.
//

@import UIKit;
#import "SMConfig.h"

@interface SMMessagesHandler : NSObject

+ (void)didOpenMessage:(NSString *_Nonnull)messageId forActivity:(NSString *_Nonnull)activityId atState:(UIApplicationState)appState;
+ (void)didOpenApp;

@end


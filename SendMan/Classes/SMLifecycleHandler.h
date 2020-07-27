//
//  SMLifecycleHandler.h
//  SendMan
//
//  Created by Anat Sheba Harari on 30/03/2020.
//

@import UIKit;
#import <UserNotifications/UserNotifications.h>
#import "SMConfig.h"

@interface SMLifecycleHandler : NSObject

+ (id _Nonnull )sharedManager;

- (void)applicationLaunchedWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *_Nullable)launchOptions;
- (void)applicationRegisteredToRemoteNotificationsWithDeviceToken:(NSData *_Nullable)deviceToken;
- (void)applicationFailedToRegisterForRemoteNotificationsWithError:(NSError *_Nullable)error;
- (void)applicationReceivedRemoteNotificationWithInfo:(NSDictionary *_Nullable)userInfo;
- (void)applicationReceivedRemoteNotification:(UNNotification *_Nullable)notification;
- (void)applicationReceivedRemoteNotificationResponse:(UNNotificationResponse *_Nullable)response;

- (void)registerForRemoteNotifications:(void (^_Nullable)(BOOL granted))success;

@end


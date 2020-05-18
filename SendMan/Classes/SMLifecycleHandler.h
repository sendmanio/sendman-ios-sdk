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

- (void)didOpenMessage:(NSString *_Nonnull)messageId forActivity:(NSString *_Nonnull)activityId atState:(UIApplicationState)appState;
- (void)didOpenApp;

- (void)application:(UIApplication *_Nonnull)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *_Nullable)launchOptions;
- (void)application:(UIApplication *_Nonnull)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *_Nullable)deviceToken;
- (void)application:(UIApplication *_Nonnull)application didFailToRegisterForRemoteNotificationsWithError:(NSError *_Nullable)error;
- (void)application:(UIApplication *_Nonnull)application didReceiveRemoteNotification:(NSDictionary *_Nullable)userInfo fetchCompletionHandler:(void (^_Nullable)(UIBackgroundFetchResult result))completionHandler;
- (void)userNotificationCenter:(UNUserNotificationCenter *_Nonnull)center openSettingsForNotification:(UNNotification *_Nullable)notification;
- (void)userNotificationCenter:(UNUserNotificationCenter *_Nonnull)center willPresentNotification:(UNNotification *_Nullable)notification withCompletionHandler:(void (^_Nullable)(UNNotificationPresentationOptions))completionHandler;
- (void)userNotificationCenter:(UNUserNotificationCenter *_Nonnull)center didReceiveNotificationResponse:(UNNotificationResponse *_Nullable)response withCompletionHandler:(void (^_Nullable)(void))completionHandler;

@end


//
//  Sendman.h
//  SendMan
//
//  Created by Anat Sheba Harari on 30/03/2020.
//

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>
#import "SMConfig.h"
#import "SMNotificationsViewController.h"

@import UIKit;

#define CategoriesRetrievedNotification @"CategoriesRetrievedNotification"

@interface Sendman : NSObject

+ (SMConfig * _Nullable)getConfig;
+ (NSString * _Nullable)getUserId;

+ (void)setAppConfig:(SMConfig *_Nonnull)config;
+ (void)setUserId:(NSString *_Nonnull)userId;
+ (void)setAPNToken:(NSString *_Nonnull)token;

+ (SMNotificationsViewController *_Nonnull)getCategoriesUIViewController;
+ (void)setUserCategories:(NSArray *_Nonnull)categories;
+ (void)updateUserCategories:(NSArray *_Nonnull)categories;
+ (NSArray * _Nullable)getCategories;

+ (void)setUserProperties:(NSDictionary *_Nonnull)properties;
+ (void)addUserEvent:(NSString *_Nonnull)eventName;
+ (void)addUserEvent:(NSString *_Nonnull)eventName stringValue:(NSString *_Nullable)value;
+ (void)addUserEvent:(NSString *_Nonnull)eventName numberValue:(NSNumber *_Nonnull)value;
+ (void)addUserEvent:(NSString *_Nonnull)eventName booleanValue:(BOOL)value;

+ (void)application:(UIApplication *_Nonnull)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *_Nullable)launchOptions;
+ (void)application:(UIApplication *_Nonnull)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *_Nullable)deviceToken;
+ (void)application:(UIApplication *_Nonnull)application didFailToRegisterForRemoteNotificationsWithError:(NSError *_Nullable)error;
+ (void)application:(UIApplication *_Nonnull)application didReceiveRemoteNotification:(NSDictionary *_Nullable)userInfo fetchCompletionHandler:(void (^_Nullable)(UIBackgroundFetchResult result))completionHandler;
+ (void)userNotificationCenter:(UNUserNotificationCenter *_Nonnull)center openSettingsForNotification:(UNNotification *_Nullable)notification;
+ (void)userNotificationCenter:(UNUserNotificationCenter *_Nonnull)center willPresentNotification:(UNNotification *_Nullable)notification withCompletionHandler:(void (^_Nullable)(UNNotificationPresentationOptions))completionHandler;
+ (void)userNotificationCenter:(UNUserNotificationCenter *_Nonnull)center didReceiveNotificationResponse:(UNNotificationResponse *_Nullable)response withCompletionHandler:(void (^_Nullable)(void))completionHandler;

+ (void)registerForRemoteNotifications;

@end


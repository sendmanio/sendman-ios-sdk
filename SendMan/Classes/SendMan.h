//
//  SendMan.h
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

@interface SendMan : NSObject

# pragma mark - Getters

+ (SMConfig * _Nullable)getConfig;
+ (NSString * _Nullable)getUserId;

# pragma mark - Global parameters

+ (void)setAppConfig:(SMConfig *_Nonnull)config;
+ (void)setUserId:(NSString *_Nonnull)userId;
+ (void)setAPNToken:(NSString *_Nonnull)token;

# pragma mark - Categories

+ (SMNotificationsViewController *_Nonnull)getCategoriesUIViewController;
+ (void)setUserCategories:(NSArray *_Nonnull)categories;
+ (void)updateUserCategories:(NSArray *_Nonnull)categories;
+ (NSArray * _Nullable)getCategories;

# pragma mark - User Properties

+ (void)setUserProperties:(NSDictionary *_Nonnull)properties;

# pragma mark - User Events

+ (void)addUserEvent:(NSString *_Nonnull)eventName;
+ (void)addUserEvent:(NSString *_Nonnull)eventName stringValue:(NSString *_Nullable)value;
+ (void)addUserEvent:(NSString *_Nonnull)eventName numberValue:(NSNumber *_Nonnull)value;
+ (void)addUserEvent:(NSString *_Nonnull)eventName booleanValue:(BOOL)value;

# pragma mark - Integration Events

+ (void)applicationLaunchedWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *_Nullable)launchOptions;
+ (void)applicationRegisteredToRemoteNotificationsWithDeviceToken:(NSData *_Nullable)deviceToken;
+ (void)applicationFailedToRegisterForRemoteNotificationsWithError:(NSError *_Nullable)error;
+ (void)applicationReceivedRemoteNotificationWithInfo:(NSDictionary *_Nullable)userInfo;
+ (void)applicationReceivedRemoteNotification:(UNNotification *_Nullable)notification;
+ (void)applicationReceivedRemoteNotificationResponse:(UNNotificationResponse *_Nullable)response;

# pragma mark - Notification Registration (Optional)

+ (void)registerForRemoteNotifications:(void (^_Nullable)(BOOL granted))success;

@end

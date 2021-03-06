//
//  SendMan.h
//  Copyright © 2020 SendMan Inc. (https://sendman.io/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>
#import <SendMan/SMConfig.h>
#import <SendMan/SMNotificationsViewController.h>
#import <SendMan/SMCategory.h>

@import UIKit;

#define kSMAutoUserId @"kSMAutoUserId"

@interface SendMan : NSObject

# pragma mark - Getters

+ (SMConfig * _Nullable)getConfig;
+ (NSString * _Nullable)getUserId;
+ (BOOL)isSdkInitialized;
+ (NSString * _Nonnull)getSDKVersion;

# pragma mark - Global parameters

+ (void)setAppConfig:(SMConfig *_Nonnull)config;
+ (void)setUserId:(NSString *_Nonnull)userId;
+ (void)setAPNToken:(NSString *_Nonnull)token;
+ (void)disableSdk;

# pragma mark - Categories

+ (SMNotificationsViewController *_Nonnull)getCategoriesUIViewController;
+ (NSArray * _Nullable)getCategories;

# pragma mark - User Properties

+ (void)setUserProperties:(NSDictionary<NSString *, id> *_Nonnull)properties;

# pragma mark - Integration Events

+ (void)applicationDidFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *_Nullable)launchOptions;
+ (void)applicationDidRegisterForRemoteNotificationsWithDeviceToken:(NSData *_Nullable)deviceToken;
+ (void)applicationDidFailToRegisterForRemoteNotificationsWithError:(NSError *_Nullable)error;
+ (void)userNotificationCenterWillPresentNotification:(UNNotification *_Nullable)notification;
+ (void)userNotificationCenterDidReceiveNotificationResponse:(UNNotificationResponse *_Nullable)response;

# pragma mark - Notification Registration (Optional)

+ (void)requestPushAuthorization:(void (^_Nullable)(BOOL granted))success;

@end

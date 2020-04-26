//
//  Sendman.h
//  SendMan
//
//  Created by Anat Sheba Harari on 30/03/2020.
//

#import <Foundation/Foundation.h>
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

+ (void)didOpenMessage:(NSString *_Nonnull)messageId atState:(UIApplicationState)appState;
+ (void)didOpenApp;



@end


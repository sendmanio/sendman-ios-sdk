//
//  MSDataCollector.h
//  Pods
//
//  Created by Anat Harari on 22/12/2019.
//

@import UIKit;
#import "MSConfig.h"

@interface MSDataCollector : NSObject

+ (void)setAppConfig:(MSConfig *_Nonnull)config;
+ (void)setUserId:(NSString *_Nonnull)userId;
+ (void)setAPNToken:(NSString *_Nonnull)token;

+ (void)setUserProperties:(NSDictionary *_Nonnull)properties;
+ (void)addUserEvent:(NSString *_Nonnull)eventName;
+ (void)addUserEvent:(NSString *_Nonnull)eventName stringValue:(NSString *_Nullable)value;
+ (void)addUserEvent:(NSString *_Nonnull)eventName numberValue:(NSNumber *_Nonnull)value;
+ (void)addUserEvent:(NSString *_Nonnull)eventName booleanValue:(BOOL)value;
+ (void)addUserEvents:(NSDictionary *_Nonnull)events;

+ (void)didOpenMessage:(NSString *_Nonnull)messageId atState:(UIApplicationState)appState;

@end

//
//  SMDataCollector.h
//  Pods
//
//  Created by Anat Harari on 22/12/2019.
//

@import UIKit;
#import "SMConfig.h"
#import "SMSDKEvent.h"

#define SMNotificationsRegistrationStateKey @"SMNotificationsRegistrationState"

@interface SMDataCollector : NSObject

+ (void)setUserProperties:(NSDictionary *_Nonnull)properties;
+ (void)setSdkProperties:(NSDictionary *_Nonnull)properties;
+ (void)addUserEvents:(NSDictionary *_Nonnull)events;
+ (void)addSdkEvent:(SMSDKEvent *_Nonnull)event;

+ (void)startSession;

@end

//
//  SMSDKEvent.h
//  SendMan
//
//  Created by Avishay Sheba Harari on 23/02/2020.
//

#import "JSONModel.h"

@protocol SMSDKEvent;

@interface SMSDKEvent : JSONModel

+ (instancetype)newWithName:(NSString *)name andValue:(NSObject *)value;

@property (nonatomic) NSString *key;
@property (nonatomic) NSObject <Optional> *value;
@property (nonatomic) NSString <Optional> *messageId;
@property (nonatomic) NSString <Optional> *activityId;
@property (nonatomic) NSNumber *timestamp;
@property (nonatomic) NSString *notificationsRegistrationState;
@property (nonatomic) NSString <Optional> *appState;

@end

//
//  SMData.h
//  SendMan
//
//  Created by Avishay Sheba Harari on 23/02/2020.
//

#import "JSONModel.h"
#import "SMCustomEvent.h"
#import "SMPropertyValue.h"
#import "SMSDKEvent.h"
#import "SMSession.h"

@protocol NSString;

@interface SMData : JSONModel

@property (nonatomic) NSString *externalUserId;
@property (nonatomic) SMSession *currentSession;
@property (nonatomic) NSDictionary<NSString *, SMPropertyValue *> <NSString, SMPropertyValue> *customProperties;
@property (nonatomic) NSDictionary<NSString *, SMPropertyValue *> <NSString, SMPropertyValue> *sdkProperties;
@property (nonatomic) NSArray<SMCustomEvent *> <SMCustomEvent> *customEvents;
@property (nonatomic) NSArray<SMSDKEvent *> <SMSDKEvent> *sdkEvents;

@end

//
//  MSData.h
//  MarketSend
//
//  Created by Avishay Sheba Harari on 23/02/2020.
//

#import "JSONModel.h"
#import "MSCustomEvent.h"
#import "MSPropertyValue.h"
#import "MSSDKEvent.h"
#import "MSSession.h"

@protocol NSString;

@interface MSData : JSONModel

@property (nonatomic) NSString *userId;
@property (nonatomic) NSString *externalUserId;
@property (nonatomic) MSSession *currentSession;
@property (nonatomic) NSDictionary<NSString *, MSPropertyValue *> <NSString, MSPropertyValue> *customProperties;
@property (nonatomic) NSDictionary<NSString *, MSPropertyValue *> <NSString, MSPropertyValue> *sdkProperties;
@property (nonatomic) NSArray<MSCustomEvent *> <MSCustomEvent> *customEvents;
@property (nonatomic) NSArray<MSSDKEvent *> <MSSDKEvent> *sdkEvents;

@end

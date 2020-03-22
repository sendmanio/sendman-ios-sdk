//
//  SMData.h
//  SendMan
//
//  Created by Avishay Sheba Harari on 23/02/2020.
//

#import "JSONModel.h"
#import "SMCustomEvent.h"
#import "SMPropertyValue.h"
#import "SSMDKEvent.h"
#import "SSMession.h"

@protocol NSString;

@interface SMData : JSONModel

@property (nonatomic) NSString *userId;
@property (nonatomic) NSString *externalUserId;
@property (nonatomic) SSMession *currentSession;
@property (nonatomic) NSDictionary<NSString *, SMPropertyValue *> <NSString, SMPropertyValue> *customProperties;
@property (nonatomic) NSDictionary<NSString *, SMPropertyValue *> <NSString, SMPropertyValue> *sdkProperties;
@property (nonatomic) NSArray<SMCustomEvent *> <SMCustomEvent> *customEvents;
@property (nonatomic) NSArray<SSMDKEvent *> <SSMDKEvent> *sdkEvents;

@end

//
//  MSSDKEvent.h
//  MarketSend
//
//  Created by Avishay Sheba Harari on 23/02/2020.
//

#import "JSONModel.h"

@protocol MSSDKEvent;

@interface MSSDKEvent : JSONModel

@property (nonatomic) NSString *key;
@property (nonatomic) NSString <Optional> *messageId;
@property (nonatomic) NSNumber *timestamp;
@property (nonatomic) NSString *appState;

@end

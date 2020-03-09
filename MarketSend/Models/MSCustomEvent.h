//
//  MSCustomEvent.h
//  MarketSend
//
//  Created by Avishay Sheba Harari on 23/02/2020.
//

#import "JSONModel.h"

@protocol MSCustomEvent;

@interface MSCustomEvent : JSONModel

@property (nonatomic) NSString *key;
@property (nonatomic) NSObject *value;
@property (nonatomic) NSNumber *timestamp;

@end

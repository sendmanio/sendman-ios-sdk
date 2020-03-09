//
//  MSPropertyValue.h
//  MarketSend
//
//  Created by Avishay Sheba Harari on 23/02/2020.
//

#import "JSONModel.h"

@protocol MSPropertyValue;

@interface MSPropertyValue : JSONModel

@property (nonatomic) NSObject *value;
@property (nonatomic) NSNumber *timestamp;

@end

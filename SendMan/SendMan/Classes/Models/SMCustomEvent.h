//
//  SMCustomEvent.h
//  SendMan
//
//  Created by Avishay Sheba Harari on 23/02/2020.
//

#import "JSONModel.h"

@protocol SMCustomEvent;

@interface SMCustomEvent : JSONModel

@property (nonatomic) NSString *key;
@property (nonatomic) NSObject *value;
@property (nonatomic) NSNumber *timestamp;

@end

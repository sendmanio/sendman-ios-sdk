//
//  SMPropertyValue.h
//  SendMan
//
//  Created by Avishay Sheba Harari on 23/02/2020.
//

#import "JSONModel.h"

@protocol SMPropertyValue;

@interface SMPropertyValue : JSONModel

@property (nonatomic) NSObject *value;
@property (nonatomic) NSNumber *timestamp;

@end

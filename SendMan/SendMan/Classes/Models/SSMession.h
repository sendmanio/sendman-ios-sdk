//
//  SSMession.h
//  Pods
//
//  Created by Avishay Sheba Harari on 23/02/2020.
//

#import "JSONModel.h"

@protocol SSMession;

@interface SSMession : JSONModel

@property (nonatomic) NSString *sessionId;
@property (nonatomic) NSNumber *start;
@property (nonatomic) NSNumber *end;

@end
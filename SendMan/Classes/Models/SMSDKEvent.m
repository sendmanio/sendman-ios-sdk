//
//  SMSDKEvent.m
//  SendMan
//
//  Created by Avishay Sheba Harari on 23/02/2020.
//

#import "SMSDKEvent.h"

@implementation SMSDKEvent

+ (instancetype)newWithName:(NSString *)name andValue:(NSObject *)value {
    SMSDKEvent *event = [SMSDKEvent new];
    event.key = name;
    event.value = value;
    return event;
}

@end

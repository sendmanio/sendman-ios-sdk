//
//  SMUtils.m
//  SendMan
//
//  Created by Anat Sheba Harari on 30/03/2020.
//

#import "SMUtils.h"

@implementation SMUtils

+ (NSNumber *)now {
    return [NSNumber numberWithLongLong:(long long)([[NSDate date] timeIntervalSince1970] * 1000.0)];
}

@end

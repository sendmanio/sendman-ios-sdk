//
//  SMConfig.m
//  SendMan
//
//  Created by Avishay Sheba on 22/12/2019.
//

#import <Foundation/Foundation.h>
#import "SMConfig.h"

@implementation SMConfig

- (instancetype)initWithKey:(NSString *)key andSecret:(NSString *)secret {
    self = [super init];
    if (self) {
        self.appKey = key;
        self.appSecret = secret;
    }
    return self;
}

@end

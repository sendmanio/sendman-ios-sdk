//
//  SMAuthHandler.h
//  SendMan
//
//  Created by Anat Sheba Harari on 26/01/2020.
//

#import <Foundation/Foundation.h>
#import "SMConfig.h"

@interface SMAuthHandler : NSObject

+ (void)addAuthHeaderToRequest:(NSMutableURLRequest *)request withConfig:(SMConfig *)config;

@end

//
//  MSAuthHandler.h
//  MarketSend
//
//  Created by Anat Sheba Harari on 26/01/2020.
//

#import <Foundation/Foundation.h>
#import "MSConfig.h"

@interface MSAuthHandler : NSObject

+ (void)addAuthHeaderToRequest:(NSMutableURLRequest *)request withConfig:(MSConfig *)config;

@end

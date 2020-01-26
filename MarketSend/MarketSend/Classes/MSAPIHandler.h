//
//  MSAPIHandler.h
//  MarketSend
//
//  Created by Anat Sheba Harari on 26/01/2020.
//

#import <Foundation/Foundation.h>
#import "MSConfig.h"

@import UIKit;

@interface MSAPIHandler : NSObject

+ (void)sendDataWithJson:(NSDictionary *)json andConfig:(MSConfig *)config forUrl:(NSString *)url responseHandler:(void (^)(NSHTTPURLResponse *httpResponse))responseHandler;

@end

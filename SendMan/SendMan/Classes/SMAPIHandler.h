//
//  SMAPIHandler.h
//  SendMan
//
//  Created by Anat Sheba Harari on 26/01/2020.
//

#import <Foundation/Foundation.h>
#import "SMConfig.h"

@import UIKit;

@interface SMAPIHandler : NSObject

+ (void)sendDataWithJson:(NSDictionary *)json andConfig:(SMConfig *)config forUrl:(NSString *)url responseHandler:(void (^)(NSHTTPURLResponse *httpResponse))responseHandler;

@end

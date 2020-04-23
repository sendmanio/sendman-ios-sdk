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

+ (void)sendDataWithJson:(NSDictionary *)json forUrl:(NSString *)url responseHandler:(void (^)(NSHTTPURLResponse *httpResponse))responseHandler;
+ (void)getDataForUrl:(NSString *)url responseHandler:(void (^)(NSHTTPURLResponse *httpResponse, NSDictionary *jsonData ))responseHandler;
@end

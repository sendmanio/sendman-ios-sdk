//
//  MSDataCollector.h
//  Pods
//
//  Created by Anat Harari on 22/12/2019.
//

@import UIKit;
#import "MSConfig.h"

@interface MSDataCollector : NSObject

@property (strong, nonatomic, nullable) MSConfig *config;

+ (id _Nonnull )sharedManager;

- (void)setUserId:(NSString *_Nonnull)userId;
- (void)setUserProperties:(NSDictionary *_Nonnull)properties;
- (void)setAPNToken:(NSString *_Nonnull)token;

@end

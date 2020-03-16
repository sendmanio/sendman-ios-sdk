//
//  SMDataEnricher.h
//  Pods
//
//  Created by Anat Sheba Harari on 20/01/2020.
//

@import UIKit;

@interface SMDataEnricher : NSObject

+ (id _Nonnull )sharedManager;

- (NSDictionary *_Nonnull)getUserEnrichedData;

@end

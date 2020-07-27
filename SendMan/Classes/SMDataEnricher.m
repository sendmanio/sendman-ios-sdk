//
//  SMDataEnricher.m
//  SendMan
//
//  Created by Anat Sheba Harari on 20/01/2020.
//

#import <Foundation/Foundation.h>
#import "SMDataEnricher.h"
#import "SMDataCollector.h"

NSString *const SMCountryCodeKey = @"SMCountryCode";
NSString *const SMLanguageCodeKey = @"SMLanguageCode";

NSString *const SMDeviceSystemNameKey = @"SMDeviceSystemName";
NSString *const SMDeviceSystemVersionKey = @"SMDeviceSystemVersion";
NSString *const SMDeviceModelKey = @"SMDeviceModel";

@implementation SMDataEnricher

# pragma mark - Data collection

+ (NSDictionary *)getUserEnrichedData {
    
    NSMutableDictionary *enrichedData = [[NSMutableDictionary alloc] init];
    
    NSLocale *currentLocale = [NSLocale currentLocale];
    enrichedData[SMCountryCodeKey] = currentLocale.countryCode;
    enrichedData[SMLanguageCodeKey] = currentLocale.languageCode;
    
    UIDevice *currentDevice = [UIDevice currentDevice];
    enrichedData[SMDeviceSystemNameKey] = currentDevice.systemName;
    enrichedData[SMDeviceSystemVersionKey] = currentDevice.systemVersion;
    enrichedData[SMDeviceModelKey] = currentDevice.model;

    return enrichedData;
    
}

@end

//
//  MSDataEnricher.m
//  MarketSend
//
//  Created by Anat Sheba Harari on 20/01/2020.
//

#import <Foundation/Foundation.h>
#import "MSDataEnricher.h"
#import "MSDataCollector.h"

NSString *const MSCountryCodeKey = @"MSCountryCode";
NSString *const MSLanguageCodeKey = @"MSLanguageCode";

NSString *const MSDeviceNameKey = @"MSDeviceName";
NSString *const MSDeviceSystemNameKey = @"MSDeviceSystemName";
NSString *const MSDeviceSystemVersionKey = @"MSDeviceSystemVersion";
NSString *const MSDeviceModelKey = @"MSDeviceModel";

@interface MSDataEnricher ()

@property (strong, nonatomic, nullable) NSMutableDictionary *enrichedData;

@end

@implementation MSDataEnricher

@synthesize enrichedData = _enrichedData;

# pragma mark - Constructor and Singletong Access

+ (id)sharedManager {
    static MSDataEnricher *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

# pragma mark - Data collection

- (NSDictionary *)getUserEnrichedData {
    
    self.enrichedData = [[NSMutableDictionary alloc] init];
    
    NSLocale *currentLocale = [NSLocale currentLocale];
    if (@available(iOS 10.0, *)) {
        self.enrichedData[MSCountryCodeKey] = currentLocale.countryCode;
        self.enrichedData[MSLanguageCodeKey] = currentLocale.languageCode;
    }
    
    UIDevice *currentDevice = [UIDevice currentDevice];
    self.enrichedData[MSDeviceNameKey] = currentDevice.name;
    self.enrichedData[MSDeviceSystemNameKey] = currentDevice.systemName;
    self.enrichedData[MSDeviceSystemVersionKey] = currentDevice.systemVersion;
    self.enrichedData[MSDeviceModelKey] = currentDevice.model;
    
    // TODO: remove and handle bulk properties calls
    NSMutableDictionary *currentEnrichedData = self.enrichedData;
    self.enrichedData = [[NSMutableDictionary alloc] init];
    return currentEnrichedData;
    
}

@end

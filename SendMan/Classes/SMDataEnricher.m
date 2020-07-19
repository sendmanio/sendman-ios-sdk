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

@interface SMDataEnricher ()

@property (strong, nonatomic, nullable) NSMutableDictionary *enrichedData;

@end

@implementation SMDataEnricher

@synthesize enrichedData = _enrichedData;

# pragma mark - Constructor and Singletong Access

+ (id)sharedManager {
    static SMDataEnricher *sharedMyManager = nil;
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
    self.enrichedData[SMCountryCodeKey] = currentLocale.countryCode;
    self.enrichedData[SMLanguageCodeKey] = currentLocale.languageCode;
    
    UIDevice *currentDevice = [UIDevice currentDevice];
    self.enrichedData[SMDeviceSystemNameKey] = currentDevice.systemName;
    self.enrichedData[SMDeviceSystemVersionKey] = currentDevice.systemVersion;
    self.enrichedData[SMDeviceModelKey] = currentDevice.model;
    
    // TODO: remove and handle bulk properties calls
    NSMutableDictionary *currentEnrichedData = self.enrichedData;
    self.enrichedData = [[NSMutableDictionary alloc] init];
    return currentEnrichedData;
    
}

@end

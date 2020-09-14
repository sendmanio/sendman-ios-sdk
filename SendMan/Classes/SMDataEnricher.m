//
//  SMDataEnricher.m
//  Copyright © 2020 SendMan Inc. (https://sendman.io/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <Foundation/Foundation.h>
#import "SMDataEnricher.h"
#import "SMDataCollector.h"

NSString *const SMCountryCodeKey = @"SMCountryCode";
NSString *const SMLanguageCodeKey = @"SMLanguageCode";
NSString *const SMTimezoneKey = @"SMTimezone";

NSString *const SMDeviceSystemNameKey = @"SMDeviceSystemName";
NSString *const SMDeviceSystemVersionKey = @"SMDeviceSystemVersion";
NSString *const SMDeviceModelKey = @"SMDeviceModel";

NSString *const SMSDKVersionKey = @"SMSDKVersion";
NSString *const SMSDKVersionValue = @"0.0.1";

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

    NSTimeZone *currentTimeZone = [NSTimeZone localTimeZone];
    enrichedData[SMTimezoneKey] = [currentTimeZone name];

    enrichedData[SMSDKVersionKey] = SMSDKVersionValue;

    return enrichedData;
    
}

@end

//
//  MSDataCollector.m
//  MarketSend
//
//  Created by Anat Harari on 22/12/2019.
//

#import <Foundation/Foundation.h>
#import "MSDataCollector.h"
#import "MSDataEnricher.h"
#import "MSAPIHandler.h"

NSString *const MSAPNTokenKey = @"MSAPNToken";

@interface MSDataCollector ()

@property (strong, nonatomic, nullable) NSString *userId;
@property (strong, nonatomic, nullable) NSMutableDictionary *properties;
@property (strong, nonatomic, nullable) NSArray<NSString *> *events;

@end

@implementation MSDataCollector

@synthesize userId = _userId;
@synthesize properties = _properties;
@synthesize events = _events;

# pragma mark - Constructor and Singletong Access

+ (id)sharedManager {
    static MSDataCollector *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _properties = [[NSMutableDictionary alloc] init];
        [self pollForNewData];
    }
    return self;
}

- (void) pollForNewData {
    dispatch_queue_t serverDelaySimulationThread = dispatch_queue_create("MarketSendPoller", nil);
    dispatch_async(serverDelaySimulationThread, ^{
        if (self.config && [self.properties count] > 0) {
            [self sendData];
        }
        [NSThread sleepForTimeInterval:2];
        [self pollForNewData];
    });
}

# pragma mark - Data collection

- (void)setUserId:(NSString *)userId {
    _userId = userId;
    [[MSDataEnricher sharedManager] setUserEnrichedData];
}

- (void)setUserProperties:(NSDictionary *)properties {
    for (NSString* key in properties) {
        [_properties setObject:properties[key] forKey:key];
    }
}

- (void)sendData {
    NSLog(@"Preparing to send data");
    
    NSMutableDictionary *currentProperties = self.properties;
    currentProperties[@"userId"] = self.userId;
    
    self.properties = [[NSMutableDictionary alloc] init];
    
    [MSAPIHandler sendDataWithJson:currentProperties andConfig:self.config forUrl:@"user/properties" responseHandler:^(NSHTTPURLResponse *httpResponse) {
        if(httpResponse.statusCode != 204) {
            for (NSString* key in self.properties) {
                [currentProperties setObject:self.properties[key] forKey:key];
            }
            [self setUserProperties:currentProperties];
            NSLog(@"Error");
        } else {
            NSLog(@"Successfuly set properties: %@", currentProperties);
        }
    }];
}

- (void)setAPNToken:(NSString *)token {
    [self setUserProperties:@{MSAPNTokenKey: token}];
}

@end

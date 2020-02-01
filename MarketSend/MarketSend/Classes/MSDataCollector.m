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

@property (strong, nonatomic, nullable) MSConfig *config;
@property (strong, nonatomic, nullable) NSString *msUserId;
@property (strong, nonatomic, nullable) NSString *sessionId;
@property (strong, nonatomic, nullable) NSNumber *sessionIdStartTimestamp;

@property (strong, nonatomic, nullable) NSMutableDictionary *properties;
@property (strong, nonatomic, nullable) NSMutableArray *events;

@end

@implementation MSDataCollector

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
        self.properties = [[NSMutableDictionary alloc] init];
        self.events = [[NSMutableArray alloc] init];
        [self pollForNewData:2 withSessionPersistency:NO];
        [self pollForNewData:60 withSessionPersistency:YES];
    }
    return self;
}

- (void) pollForNewData:(int)secondsInterval withSessionPersistency:(BOOL)presistSession {
    dispatch_queue_t serverDelaySimulationThread = dispatch_queue_create("MarketSendDataPoller", nil);
    dispatch_async(serverDelaySimulationThread, ^{
        [self sendData:presistSession];
        [NSThread sleepForTimeInterval:secondsInterval];
        [self pollForNewData: secondsInterval withSessionPersistency:presistSession];
    });
}

# pragma mark - Data collection

+ (void)setAppConfig:(MSConfig *)config {
    MSDataCollector *manager = [MSDataCollector sharedManager];
    manager.config = config;
}

+ (void)setUserId:(NSString *)userId {
    MSDataCollector *manager = [MSDataCollector sharedManager];
    manager.msUserId = userId;
    manager.sessionId = [[NSUUID UUID] UUIDString];
    manager.sessionIdStartTimestamp = [MSDataCollector now];
    [MSDataCollector setUserProperties:[[MSDataEnricher sharedManager] getUserEnrichedData]];
}

+ (void)setAPNToken:(NSString *)token {
    [MSDataCollector setUserProperties:@{MSAPNTokenKey: token}];
}

+ (void)setUserProperties:(NSDictionary *)properties {
    MSDataCollector *manager = [MSDataCollector sharedManager];
    NSNumber *now = [MSDataCollector now];
    for (NSString* key in properties) {
        [manager.properties setObject:@{@"value" : properties[key], @"timestamp": now} forKey:key];
    }
}

+ (void)addUserEvent:(NSString *)eventName {
    [MSDataCollector addUserEvent:eventName stringValue:@""];
}

+ (void)addUserEvent:(NSString *)eventName stringValue:(NSString *)value {
    [MSDataCollector addUserEvents:@{eventName: value}];
}

+ (void)addUserEvent:(NSString *)eventName numberValue:(NSNumber *)value {
    [MSDataCollector addUserEvents:@{eventName: value}];
}

+ (void)addUserEvent:(NSString *)eventName booleanValue:(bool)value {
    [MSDataCollector addUserEvents:@{eventName: value == YES ? @"YES" : @"NO"}];
}

+ (void)addUserEvents:(NSDictionary *)events {
    MSDataCollector *manager = [MSDataCollector sharedManager];
    NSNumber *now = [MSDataCollector now];
    for (NSDictionary* eventName in events) {
        [manager.events addObject:@{@"key": eventName, @"value" : events[eventName], @"timestamp": now}];
    }
}

+ (NSNumber *)now {
    return [NSNumber numberWithLongLong:(long long)([[NSDate date] timeIntervalSince1970] * 1000.0)];
}

- (void)sendData:(BOOL)presistSession {
    
    if (!self.config || (!presistSession && ([self.properties count] == 0 && [self.events count] == 0))) {
        return;
    }
    
    NSLog(@"Preparing to send data");

    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    data[@"userId"] = self.msUserId;
    data[@"sessionId"] = self.sessionId;
    data[@"start"] = self.sessionIdStartTimestamp;
    data[@"end"] = [MSDataCollector now];
    
    NSMutableDictionary *currentProperties = self.properties;
    data[@"properties"] = self.properties;
    self.properties = [[NSMutableDictionary alloc] init];
    
    NSMutableArray *currentEvents = self.events;
    data[@"events"] = self.events;
    self.events = [[NSMutableArray alloc] init];
    
    [MSAPIHandler sendDataWithJson:data andConfig:self.config forUrl:@"user/data" responseHandler:^(NSHTTPURLResponse *httpResponse) {
        if(httpResponse.statusCode != 204) {
            for (NSString* key in self.properties) {
                [currentProperties setObject:self.properties[key] forKey:key];
            }
            self.properties = currentProperties;
            
            for (NSDictionary* event in self.events) {
                [currentEvents addObject:event];
            }
            self.events = currentEvents;
            
            NSLog(@"Error");
        } else {
            NSLog(@"Successfuly set properties: %@", data);
        }
    }];
}

@end

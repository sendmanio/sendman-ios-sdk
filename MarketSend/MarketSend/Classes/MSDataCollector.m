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
@property (strong, nonatomic, nullable) NSString *sessionId;

@property (strong, nonatomic, nullable) NSMutableDictionary *properties;
@property (strong, nonatomic, nullable) NSMutableArray *events;

@end

@implementation MSDataCollector

@synthesize userId = _userId;

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
        [self pollForNewData];
    }
    return self;
}

- (void) pollForNewData {
    dispatch_queue_t serverDelaySimulationThread = dispatch_queue_create("MarketSendPoller", nil);
    dispatch_async(serverDelaySimulationThread, ^{
        [self sendData];
        [NSThread sleepForTimeInterval:2];
        [self pollForNewData];
    });
}

# pragma mark - Data collection

- (void)setUserId:(NSString *)userId {
    _userId = userId;
    self.sessionId = [[NSUUID UUID] UUIDString];
    [[MSDataEnricher sharedManager] setUserEnrichedData];
}

- (void)setUserProperties:(NSDictionary *)properties {
    NSNumber *now = [self now];
    for (NSString* key in properties) {
        [self.properties setObject:@{@"value" : properties[key], @"timestamp": now} forKey:key];
    }
}

- (void)addUserEvent:(NSString *)eventName {
    [self addUserEvent:eventName stringValue:@""];
}

- (void)addUserEvent:(NSString *)eventName stringValue:(NSString *)value {
    [self addUserEvents:@{eventName: value}];
}

- (void)addUserEvent:(NSString *)eventName numberValue:(NSNumber *)value {
    [self addUserEvents:@{eventName: value}];
}

- (void)addUserEvent:(NSString *)eventName booleanValue:(bool)value {
    [self addUserEvents:@{eventName: value == YES ? @"YES" : @"NO"}];
}

- (void)addUserEvents:(NSDictionary *)events {
    NSNumber *now = [self now];
    for (NSDictionary* eventName in events) {
        [self.events addObject:@{@"key": eventName, @"value" : events[eventName], @"timestamp": now}];
    }
}

- (NSNumber *)now {
    return [NSNumber numberWithLongLong:(long long)([[NSDate date] timeIntervalSince1970] * 1000.0)];
}

- (void)sendData {
    
    if (!self.config || ([self.properties count] == 0 && [self.events count] == 0)) {
        return;
    }
    
    NSLog(@"Preparing to send data");

    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    data[@"userId"] = self.userId;
    data[@"sessionId"] = self.sessionId;
    
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

- (void)setAPNToken:(NSString *)token {
    [self setUserProperties:@{MSAPNTokenKey: token}];
}

@end

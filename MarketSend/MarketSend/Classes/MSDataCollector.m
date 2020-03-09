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
#import "MSData.h"

NSString *const MSAPNTokenKey = @"MSAPNToken";

typedef NSMutableDictionary<NSString *, MSPropertyValue *> <NSString, MSPropertyValue> MSMutableProperties;

@interface MSDataCollector ()

@property (strong, nonatomic, nullable) MSConfig *config;
@property (strong, nonatomic, nullable) NSString *msUserId;
@property (strong, nonatomic, nullable) NSString *sessionId;
@property (strong, nonatomic, nullable) NSNumber *sessionIdStartTimestamp;

// TODO: separate user props/events from internal ones
@property (strong, nonatomic, nullable) MSMutableProperties *customProperties;
@property (strong, nonatomic, nullable) MSMutableProperties *sdkProperties;
@property (strong, nonatomic, nullable) NSMutableArray<MSCustomEvent *> <MSCustomEvent> *customEvents;
@property (strong, nonatomic, nullable) NSMutableArray<MSSDKEvent *> <MSSDKEvent> *sdkEvents;

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
        self.customProperties = [MSMutableProperties new];
        self.sdkProperties = [MSMutableProperties new];
        self.customEvents = [NSMutableArray<MSCustomEvent> new];
        self.sdkEvents = [NSMutableArray<MSSDKEvent> new];
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
    [self setProperties:[[MSDataEnricher sharedManager] getUserEnrichedData] inState:manager.sdkProperties];
}

+ (void)setAPNToken:(NSString *)token {
    [MSDataCollector setUserProperties:@{MSAPNTokenKey: token}];
}

+ (void)setProperties:(NSDictionary *)properties inState:(MSMutableProperties *)stateProperties {
    NSNumber *now = [MSDataCollector now];
    for (NSString* key in properties) {
        MSPropertyValue *propertyValue = [MSPropertyValue new];
        propertyValue.value = properties[key];
        propertyValue.timestamp = now;
        [stateProperties setObject:propertyValue forKey:key];
    }
}

+ (void)setUserProperties:(NSDictionary *)properties {
    MSDataCollector *manager = [MSDataCollector sharedManager];
    [self setProperties:properties inState:manager.customProperties];
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

+ (void)addUserEvent:(NSString *)eventName booleanValue:(BOOL)value {
    [MSDataCollector addUserEvents:@{eventName: value == YES ? @"YES" : @"NO"}];
}

+ (void)addUserEvents:(NSDictionary *)events {
    MSDataCollector *manager = [MSDataCollector sharedManager];
    NSNumber *now = [MSDataCollector now];
    for (NSString* eventName in events) {
        MSCustomEvent *event = [MSCustomEvent new];
        event.key = eventName;
        event.value = events[eventName];
        event.timestamp = now;
        [manager.customEvents addObject:event];
    }
}

+ (void)didOpenMessage:(NSString *)messageId atState:(UIApplicationState)appState {
    MSSDKEvent *event = [MSSDKEvent new];
    event.key = appState == UIApplicationStateActive ? @"Foreground Message Received" : @"App launched";
    event.appState = [self appStateStringFromState:appState];
    event.timestamp = [MSDataCollector now];
    event.messageId = messageId;

    MSDataCollector *manager = [MSDataCollector sharedManager];
    if ([[manager.sdkEvents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"messageId == %@", messageId]] firstObject]) {
        NSLog(@"Message already handled previously");
    } else {
        [manager.sdkEvents addObject:event];
    }
}

+ (NSString *)appStateStringFromState:(UIApplicationState)state {
    switch (state) {
        case UIApplicationStateActive:
            return @"Active";
        case UIApplicationStateInactive:
            return @"Inactive";
        case UIApplicationStateBackground:
            return @"Background";
        default:
            return @"Killed";
    }
}

+ (NSNumber *)now {
    return [NSNumber numberWithLongLong:(long long)([[NSDate date] timeIntervalSince1970] * 1000.0)];
}

- (void)sendData:(BOOL)presistSession {
    
    if (!self.config || (!presistSession && ([self.customProperties count] == 0 && [self.sdkProperties count] == 0 && [self.customEvents count] == 0 && [self.sdkEvents count] == 0))) {
        return;
    }
    
    NSLog(@"Preparing to send data");

    MSData *data = [MSData new];
    data.externalUserId = self.msUserId;

    data.currentSession = [MSSession new];
    data.currentSession.sessionId = self.sessionId;
    data.currentSession.start = self.sessionIdStartTimestamp;
    data.currentSession.end = [MSDataCollector now];

    MSMutableProperties *currentCustomProperties = self.customProperties;
    data.customProperties = self.customProperties;
    self.customProperties = [MSMutableProperties new];

    MSMutableProperties *currentSDKProperties = self.sdkProperties;
    data.sdkProperties = self.sdkProperties;
    self.sdkProperties = [MSMutableProperties new];

    NSMutableArray<MSCustomEvent *> <MSCustomEvent> *currentCustomEvents = self.customEvents;
    data.customEvents = self.customEvents;
    self.customEvents = [[NSMutableArray<MSCustomEvent> alloc] init];

    NSMutableArray<MSSDKEvent *> <MSSDKEvent> *currentSDKEvents = self.sdkEvents;
    data.sdkEvents = self.sdkEvents;
    self.sdkEvents = [[NSMutableArray<MSSDKEvent> alloc] init];

    [MSAPIHandler sendDataWithJson:[data toDictionary] andConfig:self.config forUrl:@"user/data" responseHandler:^(NSHTTPURLResponse *httpResponse) {
        if(httpResponse.statusCode != 204) {
            for (NSString* key in self.customProperties) {
                [currentCustomProperties setObject:self.customProperties[key] forKey:key];
            }
            self.customProperties = currentCustomProperties;
            
            for (NSString* key in self.sdkProperties) {
                [currentSDKProperties setObject:self.sdkProperties[key] forKey:key];
            }
            self.sdkProperties = currentSDKProperties;

            for (MSCustomEvent* customEvent in self.customEvents) {
                [currentCustomEvents addObject:customEvent];
            }
            self.customEvents = currentCustomEvents;
            
            for (MSSDKEvent* sdkEvents in self.sdkEvents) {
                [currentSDKEvents addObject:sdkEvents];
            }
            self.sdkEvents = currentSDKEvents;

            NSLog(@"Error");
        } else {
            NSLog(@"Successfuly set properties: %@", [data toDictionary]);
        }
    }];
}

@end

//
//  SMDataCollector.m
//  SendMan
//
//  Created by Anat Harari on 22/12/2019.
//

#import <Foundation/Foundation.h>
#import "SMDataCollector.h"
#import "SMDataEnricher.h"
#import "SMAPIHandler.h"
#import "SMData.h"

NSString *const SMAPNTokenKey = @"SMAPNToken";

typedef NSMutableDictionary<NSString *, SMPropertyValue *> <NSString, SMPropertyValue> SMMutableProperties;

@interface SMDataCollector ()

@property (strong, nonatomic, nullable) SMConfig *config;
@property (strong, nonatomic, nullable) NSString *msUserId;
@property (strong, nonatomic, nullable) NSString *sessionId;
@property (strong, nonatomic, nullable) NSNumber *sessionIdStartTimestamp;

// TODO: separate user props/events from internal ones
@property (strong, nonatomic, nullable) SMMutableProperties *customProperties;
@property (strong, nonatomic, nullable) SMMutableProperties *sdkProperties;
@property (strong, nonatomic, nullable) NSMutableArray<SMCustomEvent *> <SMCustomEvent> *customEvents;
@property (strong, nonatomic, nullable) NSMutableArray<SSMDKEvent *> <SSMDKEvent> *sdkEvents;

@end

@implementation SMDataCollector

# pragma mark - Constructor and Singletong Access

+ (id)sharedManager {
    static SMDataCollector *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.customProperties = [SMMutableProperties new];
        self.sdkProperties = [SMMutableProperties new];
        self.customEvents = [NSMutableArray<SMCustomEvent> new];
        self.sdkEvents = [NSMutableArray<SSMDKEvent> new];
        [self pollForNewData:2 withSessionPersistency:NO];
        [self pollForNewData:60 withSessionPersistency:YES];
    }
    return self;
}

- (void) pollForNewData:(int)secondsInterval withSessionPersistency:(BOOL)presistSession {
    dispatch_queue_t serverDelaySimulationThread = dispatch_queue_create("SendManDataPoller", nil);
    dispatch_async(serverDelaySimulationThread, ^{
        [self sendData:presistSession];
        [NSThread sleepForTimeInterval:secondsInterval];
        [self pollForNewData: secondsInterval withSessionPersistency:presistSession];
    });
}

# pragma mark - Data collection

+ (void)setAppConfig:(SMConfig *)config {
    SMDataCollector *manager = [SMDataCollector sharedManager];
    manager.config = config;
}

+ (void)setUserId:(NSString *)userId {
    SMDataCollector *manager = [SMDataCollector sharedManager];
    manager.msUserId = userId;
    manager.sessionId = [[NSUUID UUID] UUIDString];
    manager.sessionIdStartTimestamp = [SMDataCollector now];
    [self setProperties:[[SMDataEnricher sharedManager] getUserEnrichedData] inState:manager.sdkProperties];
}

+ (void)setAPNToken:(NSString *)token {
    [SMDataCollector setUserProperties:@{SMAPNTokenKey: token}];
}

+ (void)setProperties:(NSDictionary *)properties inState:(SMMutableProperties *)stateProperties {
    NSNumber *now = [SMDataCollector now];
    for (NSString* key in properties) {
        SMPropertyValue *propertyValue = [SMPropertyValue new];
        propertyValue.value = properties[key];
        propertyValue.timestamp = now;
        [stateProperties setObject:propertyValue forKey:key];
    }
}

+ (void)setUserProperties:(NSDictionary *)properties {
    SMDataCollector *manager = [SMDataCollector sharedManager];
    [self setProperties:properties inState:manager.customProperties];
}

+ (void)addUserEvent:(NSString *)eventName {
    [SMDataCollector addUserEvent:eventName stringValue:@""];
}

+ (void)addUserEvent:(NSString *)eventName stringValue:(NSString *)value {
    [SMDataCollector addUserEvents:@{eventName: value}];
}

+ (void)addUserEvent:(NSString *)eventName numberValue:(NSNumber *)value {
    [SMDataCollector addUserEvents:@{eventName: value}];
}

+ (void)addUserEvent:(NSString *)eventName booleanValue:(BOOL)value {
    [SMDataCollector addUserEvents:@{eventName: value == YES ? @"YES" : @"NO"}];
}

+ (void)addUserEvents:(NSDictionary *)events {
    SMDataCollector *manager = [SMDataCollector sharedManager];
    NSNumber *now = [SMDataCollector now];
    for (NSString* eventName in events) {
        SMCustomEvent *event = [SMCustomEvent new];
        event.key = eventName;
        event.value = events[eventName];
        event.timestamp = now;
        [manager.customEvents addObject:event];
    }
}

+ (void)didOpenMessage:(NSString *)messageId atState:(UIApplicationState)appState {
    SSMDKEvent *event = [SSMDKEvent new];
    event.key = appState == UIApplicationStateActive ? @"Foreground Message Received" : @"App launched";
    event.appState = [self appStateStringFromState:appState];
    event.timestamp = [SMDataCollector now];
    event.messageId = messageId;

    SMDataCollector *manager = [SMDataCollector sharedManager];
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

    SMData *data = [SMData new];
    data.externalUserId = self.msUserId;

    data.currentSession = [SSMession new];
    data.currentSession.sessionId = self.sessionId;
    data.currentSession.start = self.sessionIdStartTimestamp;
    data.currentSession.end = [SMDataCollector now];

    SMMutableProperties *currentCustomProperties = self.customProperties;
    data.customProperties = self.customProperties;
    self.customProperties = [SMMutableProperties new];

    SMMutableProperties *currentSDKProperties = self.sdkProperties;
    data.sdkProperties = self.sdkProperties;
    self.sdkProperties = [SMMutableProperties new];

    NSMutableArray<SMCustomEvent *> <SMCustomEvent> *currentCustomEvents = self.customEvents;
    data.customEvents = self.customEvents;
    self.customEvents = [[NSMutableArray<SMCustomEvent> alloc] init];

    NSMutableArray<SSMDKEvent *> <SSMDKEvent> *currentSDKEvents = self.sdkEvents;
    data.sdkEvents = self.sdkEvents;
    self.sdkEvents = [[NSMutableArray<SSMDKEvent> alloc] init];

    [SMAPIHandler sendDataWithJson:[data toDictionary] andConfig:self.config forUrl:@"user/data" responseHandler:^(NSHTTPURLResponse *httpResponse) {
        if(httpResponse.statusCode != 204) {
            for (NSString* key in self.customProperties) {
                [currentCustomProperties setObject:self.customProperties[key] forKey:key];
            }
            self.customProperties = currentCustomProperties;
            
            for (NSString* key in self.sdkProperties) {
                [currentSDKProperties setObject:self.sdkProperties[key] forKey:key];
            }
            self.sdkProperties = currentSDKProperties;

            for (SMCustomEvent* customEvent in self.customEvents) {
                [currentCustomEvents addObject:customEvent];
            }
            self.customEvents = currentCustomEvents;
            
            for (SSMDKEvent* sdkEvents in self.sdkEvents) {
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

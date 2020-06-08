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
#import "SMUtils.h"
#import "Sendman.h"

typedef NSMutableDictionary<NSString *, SMPropertyValue *> <NSString, SMPropertyValue> SMMutableProperties;

@interface SMDataCollector ()

@property (strong, nonatomic, nullable) NSString *sessionId;
@property (strong, nonatomic, nullable) NSNumber *sessionIdStartTimestamp;

// TODO: separate user props/events from internal ones
@property (strong, nonatomic, nullable) SMMutableProperties *customProperties;
@property (strong, nonatomic, nullable) SMMutableProperties *sdkProperties;
@property (strong, nonatomic, nullable) NSMutableArray<SMCustomEvent *> <SMCustomEvent> *customEvents;
@property (strong, nonatomic, nullable) NSMutableArray<SMSDKEvent *> <SMSDKEvent> *sdkEvents;

@end

@implementation SMDataCollector

# pragma mark - Constructor and Singletong Access

+ (id)sharedManager {
    static SMDataCollector *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.customProperties = [SMMutableProperties new];
        self.sdkProperties = [SMMutableProperties new];
        self.customEvents = [NSMutableArray<SMCustomEvent> new];
        self.sdkEvents = [NSMutableArray<SMSDKEvent> new];
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

+ (void)startSession {
    SMDataCollector *manager = [SMDataCollector sharedManager];
    manager.sessionId = [[NSUUID UUID] UUIDString];
    manager.sessionIdStartTimestamp = [SMUtils now];
    [self setProperties:[[SMDataEnricher sharedManager] getUserEnrichedData] inState:manager.sdkProperties];
}

# pragma mark - Data collection

+ (void)setProperties:(NSDictionary *)properties inState:(SMMutableProperties *)stateProperties {
    NSNumber *now = [SMUtils now];
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

+ (void)setSdkProperties:(NSDictionary *)properties {
    SMDataCollector *manager = [SMDataCollector sharedManager];
    [self setProperties:properties inState:manager.sdkProperties];
}

+ (void)addUserEvents:(NSDictionary *)events {
    SMDataCollector *manager = [SMDataCollector sharedManager];
    NSNumber *now = [SMUtils now];
    for (NSString* eventName in events) {
        SMCustomEvent *event = [SMCustomEvent new];
        event.key = eventName;
        event.value = events[eventName];
        event.timestamp = now;
        [manager.customEvents addObject:event];
    }
}

+ (void)addSdkEvent:(SMSDKEvent *)event {
    SMDataCollector *manager = [SMDataCollector sharedManager];
    event.timestamp = [SMUtils now];
    [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        event.notificationsRegistrationState = [self getRegistrationStateFromStatus:settings.authorizationStatus];
        [manager.sdkEvents addObject:event];
    }];
}

+ (NSString *)getRegistrationStateFromStatus:(UNAuthorizationStatus)status {
    switch (status) {
        case UNAuthorizationStatusAuthorized:
            return @"On";
        case UNAuthorizationStatusNotDetermined:
            return @"Not requested";
        case UNAuthorizationStatusDenied:
            return @"Off";
        default:
            return @"Uknknown";
    }
}

- (void)sendData:(BOOL)presistSession {
    
    if (![Sendman getConfig] || (!presistSession && ([self.customProperties count] == 0 && [self.sdkProperties count] == 0 && [self.customEvents count] == 0 && [self.sdkEvents count] == 0))) {
        return;
    }
    
    NSLog(@"Preparing to send data");

    SMData *data = [SMData new];
    data.externalUserId = [Sendman getUserId];

    data.currentSession = [SMSession new];
    data.currentSession.sessionId = self.sessionId;
    data.currentSession.start = self.sessionIdStartTimestamp;
    data.currentSession.end = [SMUtils now];

    SMMutableProperties *currentCustomProperties = self.customProperties;
    data.customProperties = self.customProperties;
    self.customProperties = [SMMutableProperties new];

    SMMutableProperties *currentSDKProperties = self.sdkProperties;
    data.sdkProperties = self.sdkProperties;
    self.sdkProperties = [SMMutableProperties new];

    NSMutableArray<SMCustomEvent *> <SMCustomEvent> *currentCustomEvents = self.customEvents;
    data.customEvents = self.customEvents;
    self.customEvents = [[NSMutableArray<SMCustomEvent> alloc] init];

    NSMutableArray<SMSDKEvent *> <SMSDKEvent> *currentSDKEvents = self.sdkEvents;
    data.sdkEvents = self.sdkEvents;
    self.sdkEvents = [[NSMutableArray<SMSDKEvent> alloc] init];

    [SMAPIHandler sendDataWithJson:[data toDictionary] forUrl:@"user/data" responseHandler:^(NSHTTPURLResponse *httpResponse) {
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
            
            for (SMSDKEvent* sdkEvents in self.sdkEvents) {
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

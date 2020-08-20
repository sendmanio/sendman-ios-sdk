//
//  SMDataCollector.m
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
#import "SMDataCollector.h"
#import "SMDataEnricher.h"
#import "SMAPIHandler.h"
#import "SMSessionManager.h"
#import "SMData.h"
#import "SMUtils.h"
#import "SendMan.h"
#import "SMLog.h"

typedef NSMutableDictionary<NSString *, SMPropertyValue *> <NSString, SMPropertyValue> SMMutableProperties;

@interface SMDataCollector ()

// TODO: separate user props/events from internal ones
@property (strong, nonatomic, nullable) SMMutableProperties *customProperties;
@property (strong, nonatomic, nullable) SMMutableProperties *sdkProperties;
@property (strong, nonatomic, nullable) NSMutableArray<SMCustomEvent *> <SMCustomEvent> *customEvents;
@property (strong, nonatomic, nullable) NSMutableArray<SMSDKEvent *> <SMSDKEvent> *sdkEvents;

@property (nonatomic) BOOL sessionError;
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
        self.sessionError = false;
        
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
        if (!self.sessionError) {
            [NSThread sleepForTimeInterval:secondsInterval];
            [self pollForNewData: secondsInterval withSessionPersistency:presistSession];
        }
    });
}

+ (void)startSession {
    SMDataCollector *manager = [SMDataCollector sharedManager];
    [[SMSessionManager sharedManager] getOrCreateSession];
    [self setProperties:[SMDataEnricher getUserEnrichedData] inState:manager.sdkProperties];
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
    event.id = [[[NSUUID UUID] UUIDString] lowercaseString];
    [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        event.notificationsRegistrationState = [self getRegistrationStateFromStatus:settings.authorizationStatus];
        [manager.sdkEvents addObject:event];
    }];
}

+ (void)addSdkEventWithName:(NSString *)name andValue:(NSObject *)value {
    SMSDKEvent *event = [SMSDKEvent newWithName:name andValue:value];
    [SMDataCollector addSdkEvent:event];
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
            return @"Unknown";
    }
}

- (void)sendData:(BOOL)presistSession {
    
    if (self.sessionError || ![SendMan getConfig] || ![SendMan getUserId] || (!presistSession && ([self.customProperties count] == 0 && [self.sdkProperties count] == 0 && [self.customEvents count] == 0 && [self.sdkEvents count] == 0))) {
        return;
    }
    
    SENDMAN_LOG(@"Preparing to submit periodical data to API");

    SMData *data = [SMData new];
    data.externalUserId = [SendMan getUserId];

    data.currentSession = [[SMSessionManager sharedManager] getOrCreateSession];

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

            if (httpResponse.statusCode == 401) {
                if (self.sessionError == false) {
                    SENDMAN_ERROR(@"Wrong App Key or Secret - will stop sending data");
                    self.sessionError = true;
                }
            } else {
                SENDMAN_ERROR(@"Error submitting peridical data to API");
            }
            
        } else {
            SENDMAN_LOG(@"Successfully set properties: %@", [data toDictionary]);
        }
    }];
}

@end

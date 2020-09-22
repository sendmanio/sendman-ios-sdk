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

@property (strong, nonatomic, nullable) SMMutableProperties *customProperties;
@property (strong, nonatomic, nullable) SMMutableProperties *sdkProperties;
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
        id value = properties[key];
        if (value != nil && ([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]])) {
            SMPropertyValue *propertyValue = [SMPropertyValue new];
            propertyValue.value = properties[key];
            propertyValue.timestamp = now;
            [stateProperties setObject:propertyValue forKey:key];
        } else {
            SENDMAN_ERROR(@"Discarding property \"%@\" due to unsupported type. Supported types are NSNumber (numbers & booleans) and NSString. Provided type: %@", key, [value class]);
        }
    }
}

+ (void)setUserProperties:(NSDictionary<NSString *, id> *)properties {
    SMDataCollector *manager = [SMDataCollector sharedManager];
    [self setProperties:properties inState:manager.customProperties];
}

+ (void)setSdkProperties:(NSDictionary<NSString *, id> *)properties {
    SMDataCollector *manager = [SMDataCollector sharedManager];
    [self setProperties:properties inState:manager.sdkProperties];
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
    
    if (self.sessionError || ![SendMan getConfig] || ![SendMan getUserId] || (!presistSession && ([self.customProperties count] == 0 && [self.sdkProperties count] == 0 && [self.sdkEvents count] == 0))) {
        return;
    }
    
    SENDMAN_LOG(@"Preparing to submit periodical data to API");

    SMData *data = [SMData new];

    NSString *userId = [SendMan getUserId];
    NSString *autoUserId = [[NSUserDefaults standardUserDefaults] stringForKey:kSMAutoUserId];
    if (autoUserId && ![autoUserId isEqualToString:userId]) {
        data.autoUserId = autoUserId;
    }
    data.externalUserId = userId;

    data.currentSession = [[SMSessionManager sharedManager] getOrCreateSession];

    SMMutableProperties *currentCustomProperties = [self.customProperties copy];
    data.customProperties = currentCustomProperties;
    [self.customProperties removeAllObjects];

    SMMutableProperties *currentSDKProperties = [self.sdkProperties copy];
    data.sdkProperties = currentSDKProperties;
    [self.sdkProperties removeAllObjects];

    NSMutableArray<SMSDKEvent *> <SMSDKEvent> *currentSDKEvents = [self.sdkEvents copy];
    data.sdkEvents = currentSDKEvents;
    [self.sdkEvents removeAllObjects];

    NSDictionary *dataDict = [data toDictionary];
    
    [SMAPIHandler sendDataWithJson:dataDict forUrl:@"user/data" responseHandler:^(NSHTTPURLResponse *httpResponse) {
        if(httpResponse.statusCode == 204) {
            if (data.autoUserId) { // This means auto Id was just overridden in the backend by an actual externalUserId
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSMAutoUserId];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            SENDMAN_LOG(@"Successfully set properties: %@", dataDict);
        } else {
            for (NSString* key in self.customProperties) {
                [currentCustomProperties setObject:self.customProperties[key] forKey:key];
            }
            [self.customProperties setDictionary:currentCustomProperties];
            
            for (NSString* key in self.sdkProperties) {
                [currentSDKProperties setObject:self.sdkProperties[key] forKey:key];
            }
            [self.sdkProperties setDictionary:currentSDKProperties];
            
            for (SMSDKEvent* sdkEvents in self.sdkEvents) {
                [currentSDKEvents addObject:sdkEvents];
            }
            [self.sdkEvents setArray:currentSDKEvents];

            if (httpResponse.statusCode == 401) {
                if (self.sessionError == false) {
                    SENDMAN_ERROR(@"Wrong App Key or Secret - will stop sending data");
                    self.sessionError = true;
                }
            } else {
                SENDMAN_ERROR(@"Error submitting peridical data to API");
            }
        }
    }];
}

@end

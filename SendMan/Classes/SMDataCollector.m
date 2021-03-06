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
@property (nonatomic) BOOL checkActiveUser;
@property (strong, nonatomic, nullable) NSNumber *lastDataSentTs;
@property (strong, nonatomic, nullable) NSNumber *lastForegroundTime;
@property (nonatomic) UNAuthorizationStatus lastKnownAuthorizationStatus;

@property (nonatomic) NSInteger exponentialNetworkFailureBackOff;

@end

@implementation SMDataCollector

# pragma mark - Constructor and Singletong Access

static SMDataCollector *sharedManager = nil;
static dispatch_once_t onceToken;

+ (id)sharedManager {
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
        sharedManager.exponentialNetworkFailureBackOff = 1;
        [[NSNotificationCenter defaultCenter] addObserver:sharedManager selector:@selector(applicationWillGoToBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    });
    return sharedManager;
}

+ (void)reset {
    @synchronized(self) {
        sharedManager = nil;
        onceToken = 0;
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.sessionError = NO;
        self.checkActiveUser = YES;
        self.lastKnownAuthorizationStatus = -1;
        self.customProperties = [SMMutableProperties new];
        self.sdkProperties = [SMMutableProperties new];
        self.sdkEvents = [NSMutableArray<SMSDKEvent> new];
        [self pollForNewData:2];
    }
    return self;
}

- (void) pollForNewData:(int)secondsInterval {
    dispatch_queue_t serverDelaySimulationThread = dispatch_queue_create("SendManDataPoller", nil);
    dispatch_async(serverDelaySimulationThread, ^{
        [SMDataCollector updateForegroundTime];
        [self sendData:NO];
        if (!self.sessionError) {
            [NSThread sleepForTimeInterval:secondsInterval * self.exponentialNetworkFailureBackOff];
            [self pollForNewData:secondsInterval];
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
        manager.lastKnownAuthorizationStatus = settings.authorizationStatus;
        event.notificationsRegistrationState = [self getRegistrationStateFromStatus:settings.authorizationStatus];
        [manager.sdkEvents addObject:event];
    }];
}

+ (void)addSdkEventWithName:(NSString *)name andValue:(NSObject *)value {
    SMSDKEvent *event = [SMSDKEvent newWithName:name andValue:value];
    [SMDataCollector addSdkEvent:event];
}

+ (void)updateForegroundTime {
    SMDataCollector *manager = [SMDataCollector sharedManager];
    dispatch_async(dispatch_get_main_queue(), ^() {
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
            manager.lastForegroundTime = [SMUtils now];
        }
    });
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

+ (void)reportDialogDisplayed:(BOOL)reportDisplayEvent andPerform:(void (^)(void))completion {
    if (reportDisplayEvent) {
        SMSDKEvent *event = [SMSDKEvent new];
        event.key = @"Push notification permissions popup displayed";
        [SMDataCollector addSdkEvent:event];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^() {
        if (completion) completion();
    });
}

- (void)checkAuthorizationStatus {
    if (self.lastKnownAuthorizationStatus != UNAuthorizationStatusNotDetermined) return;

    [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        if (settings.authorizationStatus != UNAuthorizationStatusNotDetermined && self.lastKnownAuthorizationStatus == UNAuthorizationStatusNotDetermined) {
            SENDMAN_LOG(@"Push notification permissions requested for the first time (without using SendMan). Permission status is: %@", settings.authorizationStatus == UNAuthorizationStatusAuthorized ? @"✅" : @"❌");
            [SMDataCollector reportDialogDisplayed:YES andPerform:nil];
        }
    }];
}

- (void)applicationWillGoToBackground {
    self.lastForegroundTime = [SMUtils now];
    [self sendData:YES];
}

- (void)sendData:(BOOL)forcePersist {
    BOOL hasNewData = [self.customProperties count] != 0 || [self.sdkProperties count] != 0 || [self.sdkEvents count] != 0;
    BOOL shouldPersistData = !self.lastDataSentTs || [[SMUtils now] longLongValue] - [self.lastDataSentTs longLongValue] > 60 * 1000;

    if (self.sessionError || ![SendMan getConfig] || ![SendMan getUserId] || (!hasNewData && !shouldPersistData && !forcePersist)) {
        return;
    }

    [self checkAuthorizationStatus];

    SENDMAN_LOG(@"Preparing to submit periodical data to API");

    SMData *data = [SMData new];
    if (self.checkActiveUser) data.checkActiveUser = YES;

    NSString *userId = [SendMan getUserId];
    NSString *autoUserId = [[NSUserDefaults standardUserDefaults] stringForKey:kSMAutoUserId];
    if (autoUserId && ![autoUserId isEqualToString:userId]) {
        data.autoUserId = autoUserId;
    }
    data.externalUserId = userId;

    data.currentSession = [[SMSessionManager sharedManager] getOrCreateSession];
    data.lastForegroundTime = self.lastForegroundTime;

    SMMutableProperties *currentCustomProperties = [self.customProperties mutableCopy];
    data.customProperties = currentCustomProperties;
    [self.customProperties removeAllObjects];

    SMMutableProperties *currentSDKProperties = [self.sdkProperties mutableCopy];
    data.sdkProperties = currentSDKProperties;
    [self.sdkProperties removeAllObjects];

    NSMutableArray<SMSDKEvent *> <SMSDKEvent> *currentSDKEvents = [self.sdkEvents mutableCopy];
    data.sdkEvents = currentSDKEvents;
    [self.sdkEvents removeAllObjects];

    NSDictionary *dataDict = [data toDictionary];

    self.lastDataSentTs = [SMUtils now];
    [SMAPIHandler sendDataWithJson:dataDict forUrl:@"user/data" withResponseHandler:^(NSHTTPURLResponse *httpResponse, NSError *error) {
        if (!error && httpResponse.statusCode == 204) {
            if (data.autoUserId) { // This means auto Id was just overridden in the backend by an actual externalUserId
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSMAutoUserId];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            self.checkActiveUser = NO;
            SENDMAN_LOG(@"Successfully set properties: %@", dataDict);
            self.exponentialNetworkFailureBackOff = 1;
        } else {
            if (error.code == NSURLErrorCannotConnectToHost || error.code == NSURLErrorCannotFindHost) {
                self.exponentialNetworkFailureBackOff = self.exponentialNetworkFailureBackOff * 2;
                SENDMAN_ERROR(@"A networking error has occurred while submitting data to the server, setting retry time to %ld", (long)self.exponentialNetworkFailureBackOff);
            } else if (error != nil) {
                SENDMAN_ERROR(@"An unknown error has occurred while submitting data to the server.");
            }

            for (NSString* key in currentCustomProperties) {
                if (self.customProperties[key] == nil) {
                    self.customProperties[key] = currentCustomProperties[key];
                }
            }
            
            for (NSString* key in currentSDKProperties) {
                if (self.sdkProperties[key] == nil) {
                    self.sdkProperties[key] = currentSDKProperties[key];
                }
            }
            
            if ([currentSDKEvents count] > 0) {
                [self.sdkEvents insertObjects:currentSDKEvents atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [currentSDKEvents count])]];
            }

            if (httpResponse.statusCode == 401) {
                if (self.sessionError == false) {
                    SENDMAN_ERROR(@"Wrong App Key or Secret - will stop sending data");
                    self.sessionError = true;
                }
            } else {
                SENDMAN_ERROR(@"Error submitting periodical data to API");
            }
        }
    }];
}

@end

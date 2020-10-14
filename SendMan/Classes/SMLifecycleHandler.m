//
//  SMLifecycleHandler.m
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

#import "SMLifecycleHandler.h"
#import "SMSDKEvent.h"
#import "SMUtils.h"
#import "SMDataCollector.h"
#import "SendMan.h"
#import "SMLog.h"

@interface SMLifecycleHandler ()

@property (strong, nonatomic, nullable) NSMutableArray *lastNotificationActivities;

@end

@implementation SMLifecycleHandler

# pragma mark - Constructor and Singletong Access

+ (id)sharedManager {
    static SMDataCollector *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:sharedManager selector:@selector(applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    });
    return sharedManager;
}

# pragma mark - Cache

- (void)saveLastNotificationActivity:(NSString *)activityId {
    if (!self.lastNotificationActivities) {
        self.lastNotificationActivities = [[NSMutableArray alloc] init];
    }
    [self.lastNotificationActivities addObject:activityId];
    self.lastNotificationActivities = [NSMutableArray arrayWithArray:[self.lastNotificationActivities subarrayWithRange:NSMakeRange(0, MIN([self.lastNotificationActivities count], 100))]];
}

# pragma mark - Data collection

- (void)didOpenNotification:(NSString *)templateId forActivity:(NSString *)activityId atState:(UIApplicationState)appState {
    [self didOpenNotification:templateId forActivity:activityId atState:appState withOnSuccess:nil];
}

- (void)didOpenNotification:(NSString *)templateId forActivity:(NSString *)activityId atState:(UIApplicationState)appState withOnSuccess:(void (^)(void))onSuccess {
    if ([self.lastNotificationActivities containsObject:activityId]) {
        SENDMAN_LOG(@"Activity already handled previously");
    } else {
        [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
            [self saveLastNotificationActivity:activityId];

            SMSDKEvent *event = [SMSDKEvent new];
            event.key = [self eventNameByAppState:appState andAuthorizationStatus:settings.authorizationStatus];
            event.appState = [self appStateStringFromState:appState];
            event.templateId = templateId;
            event.activityId = activityId;
            [SMDataCollector addSdkEvent:event];

            if (onSuccess) onSuccess();
        }];
    }
}

- (void)didOpenApp {
    SMSDKEvent *event = [SMSDKEvent new];
    event.key = @"App launched";
    event.appState = [self appStateStringFromState:-1];
    [SMDataCollector addSdkEvent:event];
}

- (NSString *)appStateStringFromState:(UIApplicationState)state {
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

- (void)applicationWillEnterForeground {
    SMSDKEvent *event = [SMSDKEvent new];
    event.key = @"App entered foreground";
    event.appState = [self appStateStringFromState:UIApplicationStateBackground];
    [SMDataCollector addSdkEvent:event];

    [[UIApplication sharedApplication] registerForRemoteNotifications];
}

- (void)applicationDidFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions {
    NSDictionary *pushNotification = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    if ([self shouldHandleNotification:pushNotification]) {
        [self didOpenNotification:pushNotification[@"smTemplateId"] forActivity:pushNotification[@"smActivityId"] atState:-1 withOnSuccess:^{
            [self didOpenApp];
        }];
    } else {
        [self didOpenApp];
    }
    [[UIApplication sharedApplication] registerForRemoteNotifications];
}

- (void)applicationDidRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    const char *data = [deviceToken bytes];
    NSMutableString *token = [NSMutableString string];
    
    for (NSUInteger i = 0; i < [deviceToken length]; i++) {
        [token appendFormat:@"%02.2hhX", data[i]];
    }
    // Should create some other token by copying this string
    SENDMAN_LOG(@"The registered device token is: %@", token);
    
    [SendMan setAPNToken:token];
}

- (void)applicationDidFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    SMSDKEvent *event = [SMSDKEvent new];
    event.key = @"Failed to register to push notifications";
    [SMDataCollector addSdkEvent:event];
}

- (BOOL)shouldHandleNotification:(NSDictionary *)userInfo {
    if (userInfo && userInfo[@"smTemplateId"] && userInfo[@"smActivityId"]) return YES;

    SENDMAN_LOG(@"Discarding notification since it did not originate from SendMan.");
    return NO;
}

- (void)applicationDidReceiveRemoteNotificationWithInfo:(NSDictionary *)userInfo {
    if ([self shouldHandleNotification:userInfo]) {
        [self didOpenNotification:userInfo[@"smTemplateId"] forActivity:userInfo[@"smActivityId"] atState:[[UIApplication sharedApplication] applicationState]];
    }
}

- (void)userNotificationCenterWillPresentNotification:(UNNotification *)notification {
    [self applicationDidReceiveRemoteNotificationWithInfo:notification.request.content.userInfo];
}

- (void)userNotificationCenterDidReceiveNotificationResponse:(UNNotificationResponse *)response {
    [self userNotificationCenterWillPresentNotification:response.notification];
}

- (void)registerForRemoteNotifications:(void (^)(BOOL granted))success {
    [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        BOOL oneTimeAppleAuhtorizationDialogWasShown = settings.authorizationStatus == UNAuthorizationStatusNotDetermined;
        if (oneTimeAppleAuhtorizationDialogWasShown) {
            SENDMAN_LOG(@"Requesting push notification permissions for the first time.");
        }

        [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge)
                                                                            completionHandler:^(BOOL granted, NSError * _Nullable error) {
            SENDMAN_LOG(@"Push notification permission granted: %@", granted ? @"✅" : @"❌");
            dispatch_async(dispatch_get_main_queue(), ^() {
                if (oneTimeAppleAuhtorizationDialogWasShown) {
                    SMSDKEvent *event = [SMSDKEvent new];
                    event.key = @"Push notification permissions popup displayed";
                    [SMDataCollector addSdkEvent:event];
                }

                if (granted) {
                    [[UIApplication sharedApplication] registerForRemoteNotifications];
                }
                if (success) success(granted);
            });
        }];
    }];
}

- (NSString *)eventNameByAppState:(UIApplicationState)state andAuthorizationStatus:(UNAuthorizationStatus)status {
    if (status == UNAuthorizationStatusDenied) {
        return @"Blocked Notification Received";
    } else if (status == UNAuthorizationStatusNotDetermined) {
        return @"Pre-Authorization Notification Received";
    }

    return state == UIApplicationStateActive ? @"Foreground Notification Received" : @"Background Notification Opened";
}

@end

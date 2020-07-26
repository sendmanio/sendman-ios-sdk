//
//  SMLifecycleHandler.m
//  SendMan
//
//  Created by Anat Sheba Harari on 30/03/2020.
//

#import "SMLifecycleHandler.h"
#import "SMSDKEvent.h"
#import "SMUtils.h"
#import "SMDataCollector.h"
#import "SendMan.h"

@interface SMLifecycleHandler ()

@property (strong, nonatomic, nullable) NSMutableArray *lastMessageActivities;

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
- (void)saveLastMessageActivity:(NSString *)activityId {
    if (!self.lastMessageActivities) {
        self.lastMessageActivities = [[NSMutableArray alloc] init];
    }
    [self.lastMessageActivities addObject:activityId];
    self.lastMessageActivities = [NSMutableArray arrayWithArray:[self.lastMessageActivities subarrayWithRange:NSMakeRange(0, MIN([self.lastMessageActivities count], 100))]];
}

# pragma mark - Data collection

- (void)didOpenMessage:(NSString *)messageId forActivity:(NSString *)activityId atState:(UIApplicationState)appState {
    [self didOpenMessage:messageId forActivity:activityId atState:appState withOnSuccess:nil];
}

- (void)didOpenMessage:(NSString *)messageId forActivity:(NSString *)activityId atState:(UIApplicationState)appState withOnSuccess:(void (^)(void))onSuccess {
    if ([self.lastMessageActivities containsObject:activityId]) {
        NSLog(@"Activity already handled previously");
    } else {
        [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
            [self saveLastMessageActivity:activityId];

            SMSDKEvent *event = [SMSDKEvent new];
            event.key = [self eventNameByAppState:appState andAuthorizationStatus:settings.authorizationStatus];
            event.appState = [self appStateStringFromState:appState];
            event.messageId = messageId;
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

    [self checkNotificationRegistrationState];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
}

- (void)checkNotificationRegistrationState {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        NSString *regisrationState = [SMDataCollector getRegistrationStateFromStatus:settings.authorizationStatus];
        NSString *prevRegistrationState = [userDefaults stringForKey:SMNotificationsRegistrationStateKey];
        if (![regisrationState isEqualToString:prevRegistrationState]) {
            [userDefaults setObject:regisrationState forKey:SMNotificationsRegistrationStateKey];
            SMSDKEvent *event = [SMSDKEvent new];
            event.key = @"Notification Registration State Updated";
            event.value = regisrationState;
            [SMDataCollector addSdkEvent:event];
            [SMDataCollector setSdkProperties:@{SMNotificationsRegistrationStateKey:regisrationState}];
        }
    }];
}


- (void)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self checkNotificationRegistrationState];
    NSDictionary *pushNotification = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    if (pushNotification) {
        [self didOpenMessage:pushNotification[@"messageId"] forActivity:pushNotification[@"activityId"] atState:-1 withOnSuccess:^{
            [self didOpenApp];
        }];
    } else {
        [self didOpenApp];
    }
    [[UIApplication sharedApplication] registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [self checkNotificationRegistrationState];
    
    const char *data = [deviceToken bytes];
    NSMutableString *token = [NSMutableString string];
    
    for (NSUInteger i = 0; i < [deviceToken length]; i++) {
        [token appendFormat:@"%02.2hhX", data[i]];
    }
    // Should create some other token by copying this string
    NSLog(@"The registered device token is: %@", token);
    
    [SendMan setAPNToken:token];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    SMSDKEvent *event = [SMSDKEvent new];
    event.key = @"Failed to register to push notifications";
    [SMDataCollector addSdkEvent:event];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center openSettingsForNotification:(UNNotification *)notification {}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    NSDictionary *pushNotification = notification.request.content.userInfo;
    if (pushNotification) {
        [self didOpenMessage:pushNotification[@"messageId"] forActivity:pushNotification[@"activityId"] atState:[[UIApplication sharedApplication] applicationState]];
    }
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    NSDictionary *pushNotification = response.notification.request.content.userInfo;
    if (pushNotification) {
        [self didOpenMessage:pushNotification[@"messageId"] forActivity:pushNotification[@"activityId"] atState:[[UIApplication sharedApplication] applicationState]];
    }
}

- (void)registerForRemoteNotifications:(void (^)(BOOL granted))success {
    [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge)
                                                                        completionHandler:^(BOOL granted, NSError * _Nullable error) {
        NSLog(@"Push notification permission granted: %d", granted);
        // ?
        // TODO: should check if authorized
        dispatch_async(dispatch_get_main_queue(), ^() {
            [self checkNotificationRegistrationState];
            if (granted) {
                [[UIApplication sharedApplication] registerForRemoteNotifications];
            }
            if (success) success(granted);
        });
    }];
}

- (NSString *)eventNameByAppState:(UIApplicationState)state andAuthorizationStatus:(UNAuthorizationStatus)status {
    if (status == UNAuthorizationStatusDenied) {
        return @"Blocked Message Received";
    } else if (status == UNAuthorizationStatusNotDetermined) {
        return @"Pre-Authorization Message Received";
    }

    return state == UIApplicationStateActive ? @"Foreground Message Received" : @"Background Message Opened";
}

@end

//
//  SMAppDelegate.m
//  SendMan
//
//  Created by anatha on 12/22/2019.
//  Copyright (c) 2019 anatha. All rights reserved.
//

#import "SMAppDelegate.h"
#import <UserNotifications/UserNotifications.h>
#import <SendMan/Sendman.h>

@implementation SMAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    SMConfig *config = [[SMConfig alloc] init];
    config.appKey = @"d3b532bc03863709c219bb4abe81901e4da40159";
    config.appSecret = @"032d8ea194b263cf1d892af9cb231775e7e17588";

    [Sendman setAppConfig:config];
    [Sendman setUserId:@"123"];
    [Sendman setUserProperties:@{@"email": @"email@email.com", @"Native App": @"YES"}];

    [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge)
                                                                        completionHandler:^(BOOL granted, NSError * _Nullable error) {
        NSLog(@"Push notification permission granted: %d", granted);
        // ?
        // TODO: should check if authorized
        dispatch_async(dispatch_get_main_queue(), ^(){
            [[UIApplication sharedApplication] registerForRemoteNotifications];
        });
    }];

    // In order to receive action updates
    // TODO: merge this with subscription above
    [UNUserNotificationCenter currentNotificationCenter].delegate = self;

    NSDictionary *pushNotification = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    if (pushNotification) {
        [Sendman didOpenMessage:pushNotification[@"messageId"] forActivity:pushNotification[@"activityId"] atState:-1];
    } else {
        [Sendman didOpenApp];
    }

    // Override point for customization after application launch.
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // NSString* newStr = [[NSString alloc] initWithData:theData encoding:NSUTF8StringEncoding];
    const char *data = [deviceToken bytes];
    NSMutableString *token = [NSMutableString string];

    for (NSUInteger i = 0; i < [deviceToken length]; i++) {
        [token appendFormat:@"%02.2hhX", data[i]];
    }
    // Should create some other token by copying this string
    NSLog(@"The registered device token is: %@", token);

    [Sendman setAPNToken:token];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    NSLog(@"didReceiveRemoteNotification with completionHandler called in state %@ with userInfo: %@", [SMAppDelegate applicationState], [SMAppDelegate jsonDict:userInfo]);
    completionHandler(UIBackgroundFetchResultNoData);
    // [Active, [contentAvailable]] -> called second in foreground
    // [Active, [contentAvailable, mutableContent]] -> called second in foreground
    // [Background, [contentAvailable]] -> called on receive in background
    // [Background, [contentAvailable, mutableContent]] -> called on receive in background
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"didReceiveRemoteNotification (DEPRECATED) called in state %@ with userInfo: %@", [SMAppDelegate applicationState], [SMAppDelegate jsonDict:userInfo]);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center openSettingsForNotification:(UNNotification *)notification {
    NSLog(@"openSettingsForNotification called in state %@ with userInfo: %@", [SMAppDelegate applicationState], [SMAppDelegate jsonDict:notification.request.content.userInfo]);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    // [Active, contentAvailable] -> called first
    NSLog(@"willPresentNotification called in state %@ with userInfo: %@", [SMAppDelegate applicationState], [SMAppDelegate jsonDict:notification.request.content.userInfo]);
    NSDictionary *pushNotification = notification.request.content.userInfo;
    if (pushNotification) {
        [Sendman didOpenMessage:pushNotification[@"messageId"] forActivity:pushNotification[@"activityId"] atState:[[UIApplication sharedApplication] applicationState]];
    }
    completionHandler(UNNotificationPresentationOptionAlert);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    NSLog(@"didReceiveNotificationResponse called in state %@ with action %@ and userInfo: %@", [SMAppDelegate applicationState], response.actionIdentifier, [SMAppDelegate jsonDict:response.notification.request.content.userInfo]);
    completionHandler();
    NSDictionary *pushNotification = response.notification.request.content.userInfo;
    if (pushNotification) {
        [Sendman didOpenMessage:pushNotification[@"messageId"] forActivity:pushNotification[@"activityId"] atState:[[UIApplication sharedApplication] applicationState]];
    }

    // [Inactive, [contentAvailable]] -> called on click on default action when was in background
    // [Inactive, [contentAvailable, mutableContent]] -> called on click on default action when was in background
}

+ (NSString*) jsonDict:(NSDictionary *)d {
    NSError *error;
    if (!d) return @"{}";

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:d
                                                  options:NSJSONWritingPrettyPrinted
                                                    error:&error];

    if (!jsonData) {
       NSLog(@"%s: error: %@", __func__, error.localizedDescription);
       return @"{}";
    } else {
       return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}

+ (NSString *)applicationState {
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    return state == UIApplicationStateActive ? @"Active" : (state == UIApplicationStateInactive ? @"Inactive" : @"Background");
}


@end

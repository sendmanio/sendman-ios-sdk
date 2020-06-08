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
    config.serverUrl = @"http://localhost:4200";


    [Sendman setAppConfig:config];
    [Sendman setUserId:@"123"];
    [Sendman setUserProperties:@{@"email": @"email@email.com", @"Native App": @"YES"}];

    [UNUserNotificationCenter currentNotificationCenter].delegate = self;
    [Sendman registerForRemoteNotifications:nil];

    [Sendman application:application didFinishLaunchingWithOptions:launchOptions];

    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [Sendman application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [Sendman application:application didFailToRegisterForRemoteNotificationsWithError:error];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    NSLog(@"didReceiveRemoteNotification with completionHandler called in state %@ with userInfo: %@", [SMAppDelegate applicationState], [SMAppDelegate jsonDict:userInfo]);
    [Sendman application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
    completionHandler(UIBackgroundFetchResultNoData);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center openSettingsForNotification:(UNNotification *)notification {
    NSLog(@"openSettingsForNotification called in state %@ with userInfo: %@", [SMAppDelegate applicationState], [SMAppDelegate jsonDict:notification.request.content.userInfo]);
    [Sendman userNotificationCenter:center openSettingsForNotification:notification];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    // [Active, contentAvailable] -> called first
    NSLog(@"willPresentNotification called in state %@ with userInfo: %@", [SMAppDelegate applicationState], [SMAppDelegate jsonDict:notification.request.content.userInfo]);
    [Sendman userNotificationCenter:center willPresentNotification:notification withCompletionHandler:completionHandler];
    completionHandler(UNNotificationPresentationOptionAlert);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    NSLog(@"didReceiveNotificationResponse called in state %@ with action %@ and userInfo: %@", [SMAppDelegate applicationState], response.actionIdentifier, [SMAppDelegate jsonDict:response.notification.request.content.userInfo]);
    completionHandler();
    [Sendman userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
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

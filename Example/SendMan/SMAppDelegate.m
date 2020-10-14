//
//  SMAppDelegate.m
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

#import "SMAppDelegate.h"
#import <UserNotifications/UserNotifications.h>
#import <SendMan/SendMan.h>

@implementation SMAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    SMConfig *config = [[SMConfig alloc] initWithKey:@"d3b532bc03863709c219bb4abe81901e4da40159" andSecret:@"032d8ea194b263cf1d892af9cb231775e7e17588"];
    config.serverUrl = @"http://localhost:4200";
    [SendMan setAppConfig:config];

    [SendMan setUserId:@"123"];
    [SendMan setUserProperties:@{@"email": @"email@email.com", @"Native App": @"YES"}];

    [UNUserNotificationCenter currentNotificationCenter].delegate = self;
    [SendMan registerForRemoteNotifications:nil];

    [SendMan applicationDidFinishLaunchingWithOptions:launchOptions];

    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [SendMan applicationDidRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [SendMan applicationDidFailToRegisterForRemoteNotificationsWithError:error];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    NSLog(@"willPresentNotification called in state %@ with userInfo: %@", [SMAppDelegate applicationState], [SMAppDelegate jsonDict:notification.request.content.userInfo]);
    [SendMan userNotificationCenterWillPresentNotification:notification];
    completionHandler(UNNotificationPresentationOptionAlert);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    NSLog(@"didReceiveNotificationResponse called in state %@ with action %@ and userInfo: %@", [SMAppDelegate applicationState], response.actionIdentifier, [SMAppDelegate jsonDict:response.notification.request.content.userInfo]);
    completionHandler();
    [SendMan userNotificationCenterDidReceiveNotificationResponse:response];
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

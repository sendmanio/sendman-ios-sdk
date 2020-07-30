//
//  SendMan.m
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

#import "SendMan.h"
#import "SMUtils.h"
#import "SMDataCollector.h"
#import "SMLifecycleHandler.h"
#import "SMCategoriesHandler.h"
#import "SMNotificationsViewController.h"

NSString *const SMAPNTokenKey = @"SMAPNToken";

@interface SendMan ()

@property (strong, nonatomic, nullable) SMConfig *config;
@property (strong, nonatomic, nullable) NSString *msUserId;
@property (strong, nonatomic, nullable) NSArray *categories;

@end

@implementation SendMan

# pragma mark - Constructor and Singletong Access

+ (id)instance {
    static SendMan *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

# pragma mark - Getters

+ (SMConfig *)getConfig {
    SendMan *sendman = [SendMan instance];
    return sendman.config;
}

+ (NSString *)getUserId {
    SendMan *sendman = [SendMan instance];
    return sendman.msUserId;
}

+ (NSArray *)getCategories {
    SendMan *sendman = [SendMan instance];
    return sendman.categories;
}

# pragma mark - Global parameters

+ (void)setAppConfig:(SMConfig *)config {
    SendMan *sendman = [SendMan instance];
    sendman.config = config;
}

+ (void)setUserId:(NSString *)userId {
    SendMan *sendman = [SendMan instance];
    sendman.msUserId = userId;
    [SMDataCollector startSession];
    [SMCategoriesHandler getCategories];
}

+ (void)setAPNToken:(NSString *)token {
    [SMDataCollector setSdkProperties:@{SMAPNTokenKey: token}];
}

# pragma mark - Categories

+ (SMNotificationsViewController *)getCategoriesUIViewController {
    NSBundle *bundle = [NSBundle bundleForClass:SMNotificationsViewController.self];
    return [[UIStoryboard storyboardWithName:@"SMNotifications" bundle:bundle] instantiateViewControllerWithIdentifier:@"SMNotifications"];
}

+ (void)setUserCategories:(NSArray *)categories {
    SendMan *sendman = [SendMan instance];
    if (![sendman.categories isEqualToArray:categories]) {
        sendman.categories = categories;
        [[NSNotificationCenter defaultCenter] postNotificationName:CategoriesRetrievedNotification object:nil];
    }
}

+ (void)updateUserCategories:(NSArray *)categories {
    if (categories) {
        SendMan *sendman = [SendMan instance];
        sendman.categories = categories;
        [SMCategoriesHandler updateCategories:categories];
    }
}

# pragma mark - User Properties

+ (void)setUserProperties:(NSDictionary *)properties {
    [SMDataCollector setUserProperties:properties];
}

# pragma mark - User Events

+ (void)addUserEvent:(NSString *)eventName {
    [SMDataCollector addUserEvents:@{eventName: @""}];
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

# pragma mark - Integration Events

+ (void)applicationDidFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions {
    [[SMLifecycleHandler sharedManager] applicationDidFinishLaunchingWithOptions:launchOptions];
}

+ (void)applicationDidRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[SMLifecycleHandler sharedManager] applicationDidRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

+ (void)applicationDidFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [[SMLifecycleHandler sharedManager] applicationDidFailToRegisterForRemoteNotificationsWithError:error];
}

+ (void)applicationDidReceiveRemoteNotificationWithInfo:(NSDictionary *)userInfo {
    [[SMLifecycleHandler sharedManager] applicationDidReceiveRemoteNotificationWithInfo:userInfo];
}

+ (void)userNotificationCenterWillPresentNotification:(UNNotification *)notification {
    [[SMLifecycleHandler sharedManager] userNotificationCenterWillPresentNotification:notification];
}

+ (void)userNotificationCenterDidReceiveNotificationResponse:(UNNotificationResponse *)response {
    [[SMLifecycleHandler sharedManager] userNotificationCenterDidReceiveNotificationResponse:response];
}

# pragma mark - Notification Registration (Optional)

+ (void)registerForRemoteNotifications:(void (^)(BOOL granted))success {
    [[SMLifecycleHandler sharedManager] registerForRemoteNotifications:success];
}

@end

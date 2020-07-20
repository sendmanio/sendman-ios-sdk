//
//  Sendman.m
//  SendMan
//
//  Created by Anat Sheba Harari on 30/03/2020.
//

#import "Sendman.h"
#import "SMUtils.h"
#import "SMDataCollector.h"
#import "SMLifecycleHandler.h"
#import "SMCategoriesHandler.h"
#import "SMNotificationsViewController.h"

NSString *const SMAPNTokenKey = @"SMAPNToken";

@interface Sendman ()

@property (strong, nonatomic, nullable) SMConfig *config;
@property (strong, nonatomic, nullable) NSString *msUserId;
@property (strong, nonatomic, nullable) NSArray *categories;

@end

@implementation Sendman

# pragma mark - Constructor and Singletong Access

+ (id)instance {
    static Sendman *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

# pragma mark - Getters

+ (SMConfig *)getConfig {
    Sendman *sendman = [Sendman instance];
    return sendman.config;
}

+ (NSString *)getUserId {
    Sendman *sendman = [Sendman instance];
    return sendman.msUserId;
}

+ (NSArray *)getCategories {
    Sendman *sendman = [Sendman instance];
    return sendman.categories;
}

# pragma mark - Global parameters

+ (void)setAppConfig:(SMConfig *)config {
    Sendman *sendman = [Sendman instance];
    sendman.config = config;
}

+ (void)setUserId:(NSString *)userId {
    Sendman *sendman = [Sendman instance];
    sendman.msUserId = userId;
    [SMDataCollector startSession];
    [SMCategoriesHandler getCategories];
}

+ (void)setAPNToken:(NSString *)token {
    [SMDataCollector setSdkProperties:@{SMAPNTokenKey: token}];
}

+ (SMNotificationsViewController *)getCategoriesUIViewController {
    NSBundle *bundle = [NSBundle bundleForClass:SMNotificationsViewController.self];
    return [[UIStoryboard storyboardWithName:@"SMNotifications" bundle:bundle] instantiateViewControllerWithIdentifier:@"SMNotifications"];
}

+ (void)setUserCategories:(NSArray *)categories {
    Sendman *sendman = [Sendman instance];
    if (![sendman.categories isEqualToArray:categories]) {
        sendman.categories = categories;
        [[NSNotificationCenter defaultCenter] postNotificationName:CategoriesRetrievedNotification object:nil];
    }
}

+ (void)updateUserCategories:(NSArray *)categories {
    Sendman *sendman = [Sendman instance];
    sendman.categories = categories;
    [SMCategoriesHandler updateCategories:categories];
}



+ (void)setUserProperties:(NSDictionary *)properties {
    [SMDataCollector setUserProperties:properties];
}

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

+ (void)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    SMLifecycleHandler *manager = [SMLifecycleHandler sharedManager];
    [manager application:application didFinishLaunchingWithOptions:launchOptions];
}

+ (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[SMLifecycleHandler sharedManager] application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

+ (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [[SMLifecycleHandler sharedManager] application:application didFailToRegisterForRemoteNotificationsWithError:error];
}

+ (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    [[SMLifecycleHandler sharedManager] application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
}

+ (void)userNotificationCenter:(UNUserNotificationCenter *)center openSettingsForNotification:(UNNotification *)notification {
    [[SMLifecycleHandler sharedManager] userNotificationCenter:center openSettingsForNotification:notification];
}

+ (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    [[SMLifecycleHandler sharedManager] userNotificationCenter:center willPresentNotification:notification withCompletionHandler:completionHandler];
}

+ (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    [[SMLifecycleHandler sharedManager] userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
}

+ (void)registerForRemoteNotifications:(void (^)(BOOL granted))success {
    [[SMLifecycleHandler sharedManager] registerForRemoteNotifications:success];
}

@end

//
//  SendMan.m
//  SendMan
//
//  Created by Anat Sheba Harari on 30/03/2020.
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
    SendMan *sendman = [SendMan instance];
    sendman.categories = categories;
    [SMCategoriesHandler updateCategories:categories];
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

+ (void)applicationLaunchedWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions {
    [[SMLifecycleHandler sharedManager] applicationLaunchedWithOptions:launchOptions];
}

+ (void)applicationRegisteredToRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[SMLifecycleHandler sharedManager] applicationRegisteredToRemoteNotificationsWithDeviceToken:deviceToken];
}

+ (void)applicationFailedToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [[SMLifecycleHandler sharedManager] applicationFailedToRegisterForRemoteNotificationsWithError:error];
}

+ (void)applicationReceivedRemoteNotificationWithInfo:(NSDictionary *)userInfo {
    [[SMLifecycleHandler sharedManager] applicationReceivedRemoteNotificationWithInfo:userInfo];
}

+ (void)applicationReceivedRemoteNotification:(UNNotification *)notification {
    [[SMLifecycleHandler sharedManager] applicationReceivedRemoteNotification:notification];
}

+ (void)applicationReceivedRemoteNotificationResponse:(UNNotificationResponse *)response {
    [[SMLifecycleHandler sharedManager] applicationReceivedRemoteNotificationResponse:response];
}

# pragma mark - Notification Registration (Optional)

+ (void)registerForRemoteNotifications:(void (^)(BOOL granted))success {
    [[SMLifecycleHandler sharedManager] registerForRemoteNotifications:success];
}

@end

//
//  Sendman.m
//  SendMan
//
//  Created by Anat Sheba Harari on 30/03/2020.
//

#import "Sendman.h"
#import "SMUtils.h"
#import "SMDataCollector.h"
#import "SMMessagesHandler.h"
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
    [SMDataCollector setUserProperties:@{SMAPNTokenKey: token}];
}

+ (UIViewController *)getCategoriesUIViewController {
    NSBundle *bundle = [NSBundle bundleForClass:SMNotificationsViewController.self];
    return [[UIStoryboard storyboardWithName:@"SMNotifications" bundle:bundle] instantiateViewControllerWithIdentifier:@"SMNotifications"];
}

+ (void)setUserCategories:(NSArray *)categories {
    Sendman *sendman = [Sendman instance];
    sendman.categories = categories;
}

//TODO - only update when leaving the app
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

+ (void)didOpenMessage:(NSString *_Nonnull)messageId atState:(UIApplicationState)appState {
    [SMMessagesHandler didOpenMessage:messageId atState:appState];
}

+ (void)didOpenApp {
    [SMMessagesHandler didOpenApp];
}

@end

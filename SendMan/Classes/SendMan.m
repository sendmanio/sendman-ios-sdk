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
#import "SMLog.h"

NSString *const SMTokenKey = @"SMToken";
NSString *const SMTokenTypeKey = @"SMTokenType";

@interface SendMan ()

@property (strong, nonatomic, nullable) SMConfig *config;
@property (strong, nonatomic, nullable) NSString *smUserId;
@property (strong, nonatomic, nullable) NSArray<SMCategory *> *categories;
@property (nonatomic) BOOL sdkInitialized;

@end

@implementation SendMan

# pragma mark - Constructor and Singletong Access

+ (id)instance {
    static SendMan *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        instance.sdkInitialized = NO;
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
    return sendman.smUserId;
}

+ (NSArray *)getCategories {
    SendMan *sendman = [SendMan instance];
    return sendman.categories;
}

+ (BOOL)isSdkInitialized {
    SendMan *sendman = [SendMan instance];
    return sendman.sdkInitialized;
}

+ (NSString *)getSDKVersion {
    NSString *version;
    NSBundle *bundle = [NSBundle bundleForClass:self];
    if (bundle) {
        version = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    }

    if (!version) {
        SENDMAN_ERROR(@"Could not read version information from bundle.");
    }

    return version;
}

# pragma mark - Global parameters

+ (void)setAppConfig:(SMConfig *)config {
    SendMan *sendman = [SendMan instance];
    sendman.config = config;
    
    if (config.autoGenerateUsers) {
        NSString *autoUserId = [[NSUserDefaults standardUserDefaults] stringForKey:kSMAutoUserId];
        if (!autoUserId) {
            autoUserId = [[[NSUUID UUID] UUIDString] lowercaseString];
            [[NSUserDefaults standardUserDefaults] setObject:autoUserId forKey:kSMAutoUserId];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        [SendMan setUserIdNoValidations:autoUserId];
    }

    [self startSessionIfInitialized];
}

+ (void)setUserId:(NSString *)userId {
    if ([SendMan getConfig].autoGenerateUsers) {
        SENDMAN_ERROR(@"Cannot set userId on autoGenerateUsers mode");
    } else {
        [SendMan setUserIdNoValidations:userId];
    }
    
}

+ (void)setUserIdNoValidations:(NSString *)userId {
    SendMan *sendman = [SendMan instance];
    sendman.smUserId = userId;
    [self startSessionIfInitialized];
}


+ (void)setAPNToken:(NSString *)token {
    [SMDataCollector setSdkProperties:@{SMTokenKey: token, SMTokenTypeKey: @"apn"}];
}

+ (void)startSessionIfInitialized {
    SendMan *sendman = [SendMan instance];
    if (!sendman.sdkInitialized && sendman.config && sendman.smUserId) {
        [SMDataCollector startSession];
        [SMCategoriesHandler getCategories];
        sendman.sdkInitialized = YES;
    }
}

# pragma mark - Categories

+ (SMNotificationsViewController *)getCategoriesUIViewController {
    NSBundle *bundle = [NSBundle bundleForClass:SMNotificationsViewController.self];
    return [[UIStoryboard storyboardWithName:@"SMNotifications" bundle:bundle] instantiateViewControllerWithIdentifier:@"SMNotifications"];
}

+ (void)setUserCategories:(NSArray<SMCategory *> *)categories {
    SendMan *sendman = [SendMan instance];
    if (![sendman.categories isEqualToArray:categories]) {
        sendman.categories = categories;
        [[NSNotificationCenter defaultCenter] postNotificationName:CategoriesRetrievedNotification object:nil];
    }
}

+ (void)updateUserCategories:(NSArray<SMCategory *> *)categories {
    if (categories) {
        SendMan *sendman = [SendMan instance];
        sendman.categories = categories;
        [SMCategoriesHandler updateCategories:categories];
    }
}

# pragma mark - User Properties

+ (void)setUserProperties:(NSDictionary<NSString *, id> *)properties {
    [SMDataCollector setUserProperties:properties];
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

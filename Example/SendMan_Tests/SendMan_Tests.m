//
//  SendMan_Tests.m
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


#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SendMan/SendMan.h"
#import "SendMan/SMDataCollector.h"
#import "SendMan/SMAPIHandler.h"
#import "SendMan/SMLifecycleHandler.h"
#import "SendMan/SMCategoriesHandler.h"
#import "SendMan/SMLog.h"

NSString *const userId = @"userId";

@interface SendMan (Tests)
+ (void)reset;
@end

@interface SMDataCollector (Tests)
+ (id)sharedManager;
+ (void)reset;
- (void)sendData;
- (void)pollForNewData:(int)secondsInterval;
@property (strong, nonatomic, nullable) NSDictionary *customProperties;
@property (strong, nonatomic, nullable) NSDictionary *sdkProperties;
@property (strong, nonatomic, nullable) NSMutableArray<SMSDKEvent *> <SMSDKEvent> *sdkEvents;
@end

@interface SMLifecycleHandler (Tests)
+ (void)reset;
@property (strong, nonatomic, nullable) NSMutableArray *lastNotificationActivities;
@end

@interface SMCategoriesHandler (Tests)
@property (strong, nonatomic, nullable) NSArray<SMCategory *> *categories;
@end

@interface UNNotificationSettings (Tests)
- (instancetype)init;
@end


@interface SendMan_Tests : XCTestCase

@property (strong, nonatomic) id apiHandlerMock;

@end

@implementation SendMan_Tests

- (void)setUp {
    [SendMan reset];
    [SMDataCollector reset];
    [SMLifecycleHandler reset];
    [self initDataCollector];
    [self initCategoriesHandler];
}

- (void)tearDown {}

# pragma mark - Initialization

- (void)testSessionStartedWithConfigAndUserId {
    id dataCollectorMock = OCMClassMock([SMDataCollector class]);

    [self initializeSDK];

    [self logSomeAttributesUsingSDK];

    OCMVerify([dataCollectorMock startSession]);
}

- (void)testSessionNotStartedWithoutConfigAndUserId {
    id dataCollectorMock = OCMClassMock([SMDataCollector class]);

    [self logSomeAttributesUsingSDK];

    OCMVerify(never(), [dataCollectorMock startSession]);
}

- (void)testSessionNotStartedWithoutConfigWithUserId {
    id dataCollectorMock = OCMClassMock([SMDataCollector class]);

    [SendMan setUserId:@"userId"];

    [self logSomeAttributesUsingSDK];

    OCMVerify(never(), [dataCollectorMock startSession]);
}

- (void)testSessionNotStartedWithoutUserIdWithConfig {
    id dataCollectorMock = OCMClassMock([SMDataCollector class]);

    [SendMan setAppConfig:[[SMConfig alloc] initWithKey:@"key" andSecret:@"secret"]];

    [self logSomeAttributesUsingSDK];

    OCMVerify(never(), [dataCollectorMock startSession]);
}

# pragma mark - Pre-Initialization Public Methods

- (void)testSetUserPropertiesBeforeInitialization {
    [SendMan setUserProperties:[self validValues]];
    [SendMan setUserProperties:@{
        @"null": [NSNull null],
        @"dictionary": [self validValues],
        @"array": @[@"value", @"other"],
        @"view": [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)]
    }]; // Invalid properties

    SMDataCollector *dataCollector = [SMDataCollector sharedManager];
    XCTAssert([self compareDictKeys:dataCollector.customProperties withOtherDict:[self validValues]], @"Custom properties should contain exactly the validValues keys and nothing else.");
}

- (void)testAppLaunchWithoutNotifications {
    [self stubCurrentNotificationsStatus:UNAuthorizationStatusAuthorized];

    [SendMan applicationDidFinishLaunchingWithOptions:@{}];

    SMDataCollector *dataCollector = [SMDataCollector sharedManager];
    XCTAssertEqual(1, [dataCollector.sdkEvents count], @"Expected only a single event");
    XCTAssertEqualObjects(@"App launched", [dataCollector.sdkEvents firstObject].key, @"Expected the app launch event");
}

- (void)testAppLaunchWithNotifications {
    [self stubCurrentNotificationsStatus:UNAuthorizationStatusAuthorized];

    [SendMan applicationDidFinishLaunchingWithOptions:@{ UIApplicationLaunchOptionsRemoteNotificationKey: [self pushNotificationUserInfoPayload] }];

    SMDataCollector *dataCollector = [SMDataCollector sharedManager];
    XCTAssertEqual(2, [dataCollector.sdkEvents count], @"Expected 2 events");
    XCTAssertEqualObjects(@"Background Notification Opened", [dataCollector.sdkEvents firstObject].key, @"Expected open notification event to appear before app launch event");
    XCTAssertEqualObjects(@"App launched", [dataCollector.sdkEvents lastObject].key, @"Expected the app launch event to appear after the notification event");
}

- (void)testAppLaunchWithInvalidPayload {
    [self stubCurrentNotificationsStatus:UNAuthorizationStatusAuthorized];

    [SendMan applicationDidFinishLaunchingWithOptions:nil];

    SMDataCollector *dataCollector = [SMDataCollector sharedManager];
    XCTAssertEqual(1, [dataCollector.sdkEvents count], @"Expected only a single event");
    XCTAssertEqualObjects(@"App launched", [dataCollector.sdkEvents firstObject].key, @"Expected the app launch event");
}

- (void)testWillPresentNotification {
    [self stubCurrentNotificationsStatus:UNAuthorizationStatusAuthorized];

    [SendMan userNotificationCenterWillPresentNotification:[self notificationWithUserInfo:[self pushNotificationUserInfoPayload]]];

    SMDataCollector *dataCollector = [SMDataCollector sharedManager];
    XCTAssertEqual(1, [dataCollector.sdkEvents count], @"Expected only a single event");
    XCTAssertEqualObjects(@"Foreground Notification Received", [dataCollector.sdkEvents firstObject].key, @"Expected foreground message event");
    XCTAssertNil([dataCollector.sdkEvents firstObject].externalNotificationData, @"Should not store the entire userInfo payload for SendMan notifications");
}

- (void)testWillPresentNotificationFromExternalSource {
    [self stubCurrentNotificationsStatus:UNAuthorizationStatusAuthorized];

    [SendMan userNotificationCenterWillPresentNotification:[self notificationWithUserInfo:@{ @"param": @"value" }]];

    SMDataCollector *dataCollector = [SMDataCollector sharedManager];
    XCTAssertEqual(1, [dataCollector.sdkEvents count], @"Expected only a single event");
    XCTAssertEqualObjects(@"Foreground Notification Received", [dataCollector.sdkEvents firstObject].key, @"Expected foreground message event");
    XCTAssertNotNil([dataCollector.sdkEvents firstObject].externalNotificationData, @"Should store the entire userInfo payload for non-SendMan notifications");
}

- (void)testWillPresentNotificationFromRun {
    [self stubCurrentNotificationsStatus:UNAuthorizationStatusAuthorized];

    NSDictionary *userInfo = @{ @"param": @"value" };
    [SendMan applicationDidFinishLaunchingWithOptions:@{ UIApplicationLaunchOptionsRemoteNotificationKey: userInfo }];
    [SendMan userNotificationCenterWillPresentNotification:[self notificationWithUserInfo:userInfo]];

    SMDataCollector *dataCollector = [SMDataCollector sharedManager];
    XCTAssertEqual(2, [dataCollector.sdkEvents count], @"Expected app launch and notification open events");
    XCTAssertEqualObjects(@"Background Notification Opened", [dataCollector.sdkEvents firstObject].key, @"Expected open notification event to appear before app launch event");
    XCTAssertEqualObjects(@"App launched", [dataCollector.sdkEvents lastObject].key, @"Expected the app launch event to appear after the notification event");
    [self stubCurrentNotificationsStatus:UNAuthorizationStatusAuthorized];
}

- (void)testWillPresentNotificationIdenticalPayloadsFromDifferentNotifications {
    [self stubCurrentNotificationsStatus:UNAuthorizationStatusAuthorized];

    NSDictionary *userInfo = @{ @"param": @"value" };
    [SendMan userNotificationCenterWillPresentNotification:[self notificationWithUserInfo:userInfo]];
    [SendMan userNotificationCenterWillPresentNotification:[self notificationWithUserInfo:[NSDictionary dictionaryWithDictionary:userInfo]]];

    SMDataCollector *dataCollector = [SMDataCollector sharedManager];
    XCTAssertEqual(2, [dataCollector.sdkEvents count], @"Expected two events as they are different notifications");
    XCTAssertEqualObjects(@"Foreground Notification Received", [dataCollector.sdkEvents firstObject].key, @"Expected foreground message event");
    XCTAssertEqualObjects(@"Foreground Notification Received", [dataCollector.sdkEvents lastObject].key, @"Expected foreground message event");
}

# pragma mark - Disable SDK

- (void)testDisableSDK {
    id dataCollectorMock = OCMClassMock([SMDataCollector class]);
    id lifecycleHandlerMock = OCMPartialMock([SMLifecycleHandler sharedManager]);

    [SendMan disableSdk];

    [self initializeSDK];
    [self logSomeAttributesUsingSDK];

    [SendMan applicationDidFinishLaunchingWithOptions:@{}];
    [SendMan applicationDidRegisterForRemoteNotificationsWithDeviceToken:[NSData new]];
    [SendMan applicationDidFailToRegisterForRemoteNotificationsWithError:[NSError errorWithDomain:@"" code:0 userInfo:@{}]];
    [SendMan userNotificationCenterWillPresentNotification:[UNNotification new]];
    [SendMan userNotificationCenterDidReceiveNotificationResponse:[UNNotificationResponse new]];

    OCMVerify(never(), [dataCollectorMock setUserProperties:[OCMArg any]]);
    OCMVerify(never(), [dataCollectorMock setSdkProperties:[OCMArg any]]);
    OCMVerify(never(), [dataCollectorMock startSession]);
    OCMVerify(never(), [dataCollectorMock addSdkEvent:[OCMArg any]]);
    OCMVerify(never(), [dataCollectorMock addSdkEventWithName:[OCMArg any] andValue:[OCMArg any]]);

    OCMVerify(never(), [lifecycleHandlerMock applicationDidFinishLaunchingWithOptions:[OCMArg any]]);
    OCMVerify(never(), [lifecycleHandlerMock applicationDidRegisterForRemoteNotificationsWithDeviceToken:[OCMArg any]]);
    OCMVerify(never(), [lifecycleHandlerMock applicationDidFailToRegisterForRemoteNotificationsWithError:[OCMArg any]]);
    OCMVerify(never(), [lifecycleHandlerMock userNotificationCenterWillPresentNotification:[OCMArg any]]);
    OCMVerify(never(), [lifecycleHandlerMock userNotificationCenterDidReceiveNotificationResponse:[OCMArg any]]);
}

# pragma mark - User Properties

- (void)testSetUserPropertiesAfterInitialization {
    [SendMan setUserProperties:[self validValues]];
    [SendMan setUserProperties:@{
        @"null": [NSNull null],
        @"dictionary": [self validValues],
        @"array": @[@"value", @"other"],
        @"view": [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)]
    }]; // Invalid properties

    SMDataCollector *dataCollector = [SMDataCollector sharedManager];
    XCTAssert([self compareDictKeys:dataCollector.customProperties withOtherDict:[self validValues]], @"Custom properties should contain exactly the validValues keys and nothing else.");
}

# pragma mark - API Error Handling

- (void)testSuccessfulSendData {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[[NSURL alloc] initWithString:@""] statusCode:204 HTTPVersion:nil headerFields:nil];
    OCMStub([self.apiHandlerMock sendDataWithJson:[OCMArg any] forUrl:[OCMArg any] withResponseHandler:([OCMArg invokeBlockWithArgs:response, [NSNull null], nil])]);

    [self stubCurrentNotificationsStatus:UNAuthorizationStatusAuthorized];
    [self initializeSDK];

    [SendMan setUserProperties:[self validValues]];
    SMDataCollector *dataCollector = [SMDataCollector sharedManager];
    [dataCollector sendData];

    XCTAssertEqual(0, [dataCollector.customProperties count], @"Custom properties should be empty after a 204 response from the API.");
}

- (void)testSendDataWithAPIError {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[[NSURL alloc] initWithString:@""] statusCode:400 HTTPVersion:nil headerFields:nil];
    OCMStub([self.apiHandlerMock sendDataWithJson:[OCMArg any] forUrl:[OCMArg any] withResponseHandler:([OCMArg invokeBlockWithArgs:response, [NSNull null], nil])]);

    [self initializeSDK];

    [SendMan setUserProperties:[self validValues]];
    SMDataCollector *dataCollector = [SMDataCollector sharedManager];
    [dataCollector sendData];

    XCTAssert([self compareDictKeys:dataCollector.customProperties withOtherDict:[self validValues]], @"Custom properties should be restored and full after an error from the API.");
}

- (void)testSendDataWithNetworkError {
    OCMStub([self.apiHandlerMock sendDataWithJson:[OCMArg any] forUrl:[OCMArg any] withResponseHandler:([OCMArg invokeBlockWithArgs:[NSNull null], [NSError errorWithDomain:@"" code:0 userInfo:@{}], nil])]);

    [self initializeSDK];

    [SendMan setUserProperties:[self validValues]];
    SMDataCollector *dataCollector = [SMDataCollector sharedManager];
    [dataCollector sendData];

    XCTAssert([self compareDictKeys:dataCollector.customProperties withOtherDict:[self validValues]], @"Custom properties should be restored and full after an error from the API.");
}


# pragma mark - Categories

- (void)testUseOfCategories {
    [self initializeSDKWithCategories:YES];
    SMCategoriesHandler *categoriesHandler = [SMCategoriesHandler sharedManager];
    XCTAssertEqual(1, [categoriesHandler.categories count], @"Categories should contain a single category");
}

- (void)testNoUseOfCategories {
    [self initializeSDKWithCategories:NO];
    SMCategoriesHandler *categoriesHandler = [SMCategoriesHandler sharedManager];
    XCTAssertEqual(0, [categoriesHandler.categories count], @"Categories should should not have fetched categories");
}


# pragma mark - Private Helper Methods

- (void)logSomeAttributesUsingSDK {
    [SendMan setAPNToken:@"ABC"];
    [SendMan setUserProperties:[self validValues]];
}

- (NSDictionary *)validValues {
    return @{ @"string": @"value", @"number": @2, @"boolean": @YES };
}

- (NSDictionary *)pushNotificationUserInfoPayload {
    return @{ @"smTemplateId": @"templateId", @"smActivityId": @"activityId" };
}

- (UNNotification *)notificationWithUserInfo:(NSDictionary *)userInfo {
    id notificationContentMock = OCMClassMock([UNNotificationContent class]);
    id notificationRequestMock = OCMClassMock([UNNotificationRequest class]);
    id notificationMock = OCMClassMock([UNNotification class]);

    OCMStub([notificationContentMock userInfo]).andReturn(userInfo);
    OCMStub([notificationRequestMock content]).andReturn(notificationContentMock);
    OCMStub([notificationMock request]).andReturn(notificationRequestMock);

    return notificationMock;
}

- (void)initializeSDKWithCategories:(BOOL)useCategories {
    SMConfig *config = [[SMConfig alloc] initWithKey:@"key" andSecret:@"secret"];
    config.useCategories = useCategories;
    [SendMan setAppConfig:config];
    [SendMan setUserId:userId];
}

- (void)initializeSDK {
    [self initializeSDKWithCategories:nil];
}

- (BOOL)compareDictKeys:(NSDictionary *)dict withOtherDict:(NSDictionary *)other {
    return [[NSSet setWithArray:[dict allKeys]] isEqualToSet:[NSSet setWithArray:[other allKeys]]];
}

- (void)stubCurrentNotificationsStatus:(UNAuthorizationStatus)status {
    id notificationCenterMock = OCMClassMock([UNUserNotificationCenter class]);
    OCMStub([notificationCenterMock currentNotificationCenter]).andReturn(notificationCenterMock);

    UNNotificationSettings *settings = OCMClassMock([UNNotificationSettings class]);
    OCMStub([settings authorizationStatus]).andReturn(status);
    OCMStub([notificationCenterMock getNotificationSettingsWithCompletionHandler:([OCMArg invokeBlockWithArgs:settings, nil])]);
}

- (void)initDataCollector {
    id dataCollectorMock = OCMClassMock([SMDataCollector class]);
    OCMStub([dataCollectorMock pollForNewData:2]);
}

- (void)initCategoriesHandler {
    NSString *categoriesUrl = [NSString stringWithFormat:@"categories/user/%@", userId];
    NSDictionary *categories = @{@"categories": [NSArray arrayWithObjects:  @{@"id": @"id1"}, nil]};
    self.apiHandlerMock = OCMClassMock([SMAPIHandler class]);
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[[NSURL alloc] initWithString:@""] statusCode:200 HTTPVersion:nil headerFields:nil];
    OCMStub([self.apiHandlerMock getDataForUrl:categoriesUrl responseHandler:([OCMArg invokeBlockWithArgs:response, categories, nil])]);
}

@end

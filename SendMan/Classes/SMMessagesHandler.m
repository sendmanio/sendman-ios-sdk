//
//  SMMessagesHandler.m
//  SendMan
//
//  Created by Anat Sheba Harari on 30/03/2020.
//

#import "SMMessagesHandler.h"
#import "SMSDKEvent.h"
#import "SMUtils.h"
#import "SMDataCollector.h"

@implementation SMMessagesHandler

# pragma mark - Constructor and Singletong Access

+ (id)sharedManager {
    static SMDataCollector *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

# pragma mark - Data collection

+ (void)didOpenMessage:(NSString *_Nonnull)messageId forActivity:(NSString *_Nonnull)activityId atState:(UIApplicationState)appState {
    SMSDKEvent *event = [SMSDKEvent new];
    event.key = appState == UIApplicationStateActive ? @"Foreground Message Received" : @"App launched";
    event.appState = [self appStateStringFromState:appState];
    event.timestamp = [SMUtils now];
    event.messageId = messageId;
    event.activityId = activityId;

    if ([[[SMDataCollector getSdkEvents] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"activityId == %@", activityId]] firstObject]) {
        NSLog(@"Activity already handled previously");
    } else {
        [SMDataCollector addSdkEvent:event];
    }
}

+ (void)didOpenApp {
    SMSDKEvent *event = [SMSDKEvent new];
    event.key = @"App launched";
    event.appState = [self appStateStringFromState:-1];
    event.timestamp = [SMUtils now];
    [SMDataCollector addSdkEvent:event];
}

+ (NSString *)appStateStringFromState:(UIApplicationState)state {
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

@end

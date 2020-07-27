//
//  SMCategoriesHandler.m
//  SendMan
//
//  Created by Anat Sheba Harari on 29/03/2020.
//

#import <Foundation/Foundation.h>
#import "SMCategoriesHandler.h"
#import "SMAPIHandler.h"
#import "SendMan.h"
#import "SMDataCollector.h"
#import "SMLog.h"


@interface SMCategoriesHandler ()

@property (strong, nonatomic, nullable) NSMutableDictionary *enrichedData;

@end

@implementation SMCategoriesHandler

@synthesize enrichedData = _enrichedData;

# pragma mark - Constructor and Singletong Access

+ (id)sharedManager {
    static SMCategoriesHandler *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

//TODO retries
+ (void)getCategories {
    [SMAPIHandler getDataForUrl:[NSString stringWithFormat:@"categories/user/%@", [SendMan getUserId]] responseHandler:^(NSHTTPURLResponse *httpResponse, NSDictionary *jsonData) {
        if (httpResponse.statusCode == 200) {
            NSArray *categories = jsonData ? jsonData[@"categories"] : [[NSArray alloc] init];
            [SendMan setUserCategories: categories];
        } else {
            SENDMAN_ERROR(@"Error getting categories data");
        }
    }];
}

+ (void)updateCategories:(NSArray *)categories {
    [SMAPIHandler sendDataWithJson:@{@"categories": categories} forUrl:[NSString stringWithFormat:@"categories/user/%@", [SendMan getUserId]] responseHandler:^(NSHTTPURLResponse *httpResponse) {
        if (httpResponse.statusCode != 200) {
            SENDMAN_ERROR(@"Error updating category preferences");
        } else {
            [SMDataCollector addSdkEventWithName:@"User categories saved" andValue:nil];
        }
    }];
}

@end

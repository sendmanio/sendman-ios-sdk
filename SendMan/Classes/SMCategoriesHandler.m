//
//  SMCategoriesHandler.m
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

#import <Foundation/Foundation.h>
#import "SMCategoriesHandler.h"
#import "SMAPIHandler.h"
#import "SendMan.h"
#import "SMDataCollector.h"
#import "SMLog.h"


@implementation SMCategoriesHandler

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
            NSError *error;
            NSArray<SMCategory *> *categories = jsonData ? [SMCategory arrayOfModelsFromDictionaries:jsonData[@"categories"] error:&error] : [[NSArray alloc] init];
            if (error) {
                SENDMAN_ERROR(@"Error getting categories data - bad JSON response %@", jsonData);
            }
            [SendMan setUserCategories: categories];
        } else {
            SENDMAN_ERROR(@"Error getting categories data");
        }
    }];
}

+ (void)updateCategories:(NSArray<SMCategory *> *)categories {
    [SMAPIHandler sendDataWithJson:@{@"categories": [JSONModel arrayOfDictionariesFromModels:categories]}
                            forUrl:[NSString stringWithFormat:@"categories/user/%@", [SendMan getUserId]]
                   responseHandler:^(NSHTTPURLResponse *httpResponse) {
        if (httpResponse.statusCode != 200) {
            SENDMAN_ERROR(@"Error updating category preferences");
        } else {
            [SMDataCollector addSdkEventWithName:@"User categories saved" andValue:nil];
        }
    }];
}

@end

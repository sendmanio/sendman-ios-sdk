//
//  SMAPIHandler.m
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

#import "SMAPIHandler.h"
#import "SMAuthHandler.h"
#import "SendMan.h"
#import "SMLog.h"

@implementation SMAPIHandler

+ (void)sendDataWithJson:(NSDictionary *)json forUrl:(NSString *)url responseHandler:(void (^)(NSHTTPURLResponse *httpResponse))responseHandler {
    NSMutableURLRequest *urlRequest = [SMAPIHandler createURLRequest:url forMethodType:@"POST"];

    NSError *error;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&error];
    [urlRequest setHTTPBody:jsonData];

    NSURLSession *session = [NSURLSession sharedSession];
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            SENDMAN_ERROR(@"Error posting data via API: %@", error.localizedDescription);
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        responseHandler(httpResponse);
    }];
    [dataTask resume];
}

+ (void)getDataForUrl:(NSString *)url responseHandler:(void (^)(NSHTTPURLResponse *httpResponse, NSDictionary *jsonData ))responseHandler {
    NSMutableURLRequest *urlRequest = [SMAPIHandler createURLRequest:url forMethodType:@"GET"];

    NSURLSession *session = [NSURLSession sharedSession];
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            SENDMAN_ERROR(@"Error getting data via API: %@", error.localizedDescription);
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        responseHandler(httpResponse, jsonData);


    }];
    [dataTask resume];
}

+(NSMutableURLRequest *)createURLRequest:(NSString *)path forMethodType:(NSString *)methodType{
    // TODO: URL
    SMConfig *config = [SendMan getConfig];
    NSString *serverUrl = config.serverUrl ? config.serverUrl : @"https://api.sendman.io/app-sdk";
    NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", serverUrl, path]];
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:requestURL];

    [urlRequest setHTTPMethod:methodType];
    [SMAuthHandler addAuthHeaderToRequest:urlRequest];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    return urlRequest;
}

@end

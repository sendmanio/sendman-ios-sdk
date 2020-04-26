//
//  SMAPIHandler.m
//  SendMan
//
//  Created by Anat Sheba Harari on 26/01/2020.
//

#import "SMAPIHandler.h"
#import "SMAuthHandler.h"
#import "Sendman.h"

@implementation SMAPIHandler

+ (void)sendDataWithJson:(NSDictionary *)json forUrl:(NSString *)url responseHandler:(void (^)(NSHTTPURLResponse *httpResponse))responseHandler {
    NSMutableURLRequest *urlRequest = [SMAPIHandler createURLRequest:url forMethodType:@"POST"];

    NSError *error;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&error];
    [urlRequest setHTTPBody:jsonData];

    NSURLSession *session = [NSURLSession sharedSession];
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"%@", error.localizedDescription);
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
            NSLog(@"%@", error.localizedDescription);
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
    SMConfig *config = [Sendman getConfig];
    NSString *serverUrl = config.serverUrl ? config.serverUrl : @"http://localhost:4200";
    NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", serverUrl, path]];
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:requestURL];

    [urlRequest setHTTPMethod:methodType];
    [SMAuthHandler addAuthHeaderToRequest:urlRequest];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    return urlRequest;
}

@end

//
//  SMAPIHandler.m
//  SendMan
//
//  Created by Anat Sheba Harari on 26/01/2020.
//

#import "SMAPIHandler.h"
#import "SMAuthHandler.h"

@implementation SMAPIHandler

+ (void)sendDataWithJson:(NSDictionary *)json andConfig:(SMConfig *)config forUrl:(NSString *)url responseHandler:(void (^)(NSHTTPURLResponse *httpResponse))responseHandler {
    // TODO: URL
    NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:4200/%@", url]];
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:requestURL];

    [urlRequest setHTTPMethod:@"POST"];

    NSError *error;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&error];

    [urlRequest setHTTPBody:jsonData];
    
    [SMAuthHandler addAuthHeaderToRequest:urlRequest withConfig:config];
    
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSURLSession *session = [NSURLSession sharedSession];
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        responseHandler(httpResponse);

        if (error) {
            NSLog(@"There was an error with sending data!");
        }
    }];
    [dataTask resume];
}

@end

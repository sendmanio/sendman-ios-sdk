//
//  MSAPI.m
//  MarketSend
//
//  Created by Anat Harari on 22/12/2019.
//

#import <Foundation/Foundation.h>
#import "MSDataCollector.h"

@interface MSDataCollector ()

@property (strong, nonatomic, nullable) NSString *userId;
@property (strong, nonatomic, nullable) NSString *apnToken;

@end

@implementation MSDataCollector

@synthesize userId = _userId;
@synthesize apnToken = _apnToken;

# pragma mark - Constructor and Singletong Access

+ (id)sharedManager {
    static MSDataCollector *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

# pragma mark - Data collection

- (void)setUserId:(NSString *)userId {
    _userId = userId;
}

- (void)setUserProperties:(NSDictionary *)properties {
    // TODO: URL
    // TODO: what if config is not set
    NSURL *requestURL = [NSURL URLWithString:@"http://192.168.1.28:4200/user/properties"];
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:requestURL];

    NSMutableDictionary *userProperties = [NSMutableDictionary dictionaryWithDictionary:properties];
    userProperties[@"userId"] = self.userId;
    userProperties[@"apnToken"] = self.apnToken;

    [urlRequest setHTTPMethod:@"POST"];

    NSError *error;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:userProperties options:NSJSONWritingPrettyPrinted error:&error];

    [urlRequest setHTTPBody:jsonData];
        
    NSString *authStr = [NSString stringWithFormat:@"%@:%@", self.config.appKey, self.config.appSecret];
    NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", [[NSString alloc] initWithData:[authData base64EncodedDataWithOptions:NSDataBase64EncodingEndLineWithLineFeed] encoding:NSASCIIStringEncoding]];
    [urlRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
    
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSURLSession *session = [NSURLSession sharedSession];
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if(httpResponse.statusCode != 204) {
            NSLog(@"Error");
        } else {
            NSLog(@"Successfuly set properties: %@", properties);
        }
    }];
    [dataTask resume];
}

- (void)setAPNToken:(NSString *)token {
    _apnToken = token;
    [self setUserProperties:@{}];
}

@end

//
//  SMAuthHandler.m
//  SendMan
//
//  Created by Anat Sheba Harari on 26/01/2020.
//

#import "SMAuthHandler.h"
#import "SendMan.h"

@implementation SMAuthHandler

+ (void)addAuthHeaderToRequest:(NSMutableURLRequest *)request {
    SMConfig *config = [SendMan getConfig];
    NSString *authStr = [NSString stringWithFormat:@"%@:%@", config.appKey, config.appSecret];
    NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", [[NSString alloc] initWithData:[authData base64EncodedDataWithOptions:NSDataBase64EncodingEndLineWithLineFeed] encoding:NSASCIIStringEncoding]];
    [request setValue:authValue forHTTPHeaderField:@"Authorization"];
}

@end

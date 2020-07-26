//
//  SMConfig.h
//  Pods
//
//  Created by Avishay Sheba on 22/12/2019.
//

@interface SMConfig : NSObject

- (instancetype)initWithKey:(NSString *)key andSecret:(NSString *)secret;

@property (strong, nonatomic, nonnull) NSString *appKey;
@property (strong, nonatomic, nonnull) NSString *appSecret;
@property (strong, nonatomic, nonnull) NSString *serverUrl;

@end

//
//  SMSessionManager.m
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


#import "SMSessionManager.h"
#import "SMUtils.h"

#define kSMSession                      @"kSMSession"

#define MAX_SESSION_LENGTH_MS           10 * 60 * 1000


@implementation SMSessionManager

+ (id)sharedManager {
    static SMSessionManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (SMSession *)getOrCreateSession {
    SMSession *session = [self getLastSession];
    if (!session || ([[SMUtils now] longLongValue] - [session.end longLongValue] > MAX_SESSION_LENGTH_MS)) {
        session = [self createNewSession];
    }
    
    session.end = [SMUtils now];
    [self setLastSession:session];

    return session;
}

# pragma mark - Private logic

- (SMSession *)createNewSession {
    SMSession *session = [SMSession new];
    session.sessionId = [[NSUUID UUID] UUIDString];
    session.start = [SMUtils now];
    session.end = [SMUtils now];
    return session;
}


# pragma mark - Private setters & getters

- (void)setLastSession:(SMSession *)session {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[session toJSONString] forKey:kSMSession];
    [defaults synchronize];
}

- (SMSession *)getLastSession {
    NSString *storedSessionJSON = [[NSUserDefaults standardUserDefaults] objectForKey:kSMSession];
    if (!storedSessionJSON) return nil;
    
    NSError *error;
    return [[SMSession alloc] initWithString:storedSessionJSON error:&error];
}


@end

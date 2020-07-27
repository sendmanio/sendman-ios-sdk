//
//  SMData.h
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

#import "JSONModel.h"
#import "SMCustomEvent.h"
#import "SMPropertyValue.h"
#import "SMSDKEvent.h"
#import "SMSession.h"

@protocol NSString;

@interface SMData : JSONModel

@property (nonatomic) NSString *externalUserId;
@property (nonatomic) SMSession *currentSession;
@property (nonatomic) NSDictionary<NSString *, SMPropertyValue *> <NSString, SMPropertyValue> *customProperties;
@property (nonatomic) NSDictionary<NSString *, SMPropertyValue *> <NSString, SMPropertyValue> *sdkProperties;
@property (nonatomic) NSArray<SMCustomEvent *> <SMCustomEvent> *customEvents;
@property (nonatomic) NSArray<SMSDKEvent *> <SMSDKEvent> *sdkEvents;

@end

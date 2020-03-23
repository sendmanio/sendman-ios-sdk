#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "JSONModel.h"
#import "JSONModelClassProperty.h"
#import "JSONModelError.h"
#import "JSONModelLib.h"
#import "JSONKeyMapper.h"
#import "JSONValueTransformer.h"
#import "SMCustomEvent.h"
#import "SMData.h"
#import "SMPropertyValue.h"
#import "SSMDKEvent.h"
#import "SSMession.h"
#import "SMAPIHandler.h"
#import "SMAuthHandler.h"
#import "SMConfig.h"
#import "SMDataCollector.h"
#import "SMDataEnricher.h"

FOUNDATION_EXPORT double SendManVersionNumber;
FOUNDATION_EXPORT const unsigned char SendManVersionString[];

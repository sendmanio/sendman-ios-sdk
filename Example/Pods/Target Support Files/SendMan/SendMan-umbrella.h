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
#import "SMSDKEvent.h"
#import "SMSession.h"
#import "Sendman.h"
#import "SMAPIHandler.h"
#import "SMAuthHandler.h"
#import "SMCategoriesHandler.h"
#import "SMConfig.h"
#import "SMDataCollector.h"
#import "SMDataEnricher.h"
#import "SMLifecycleHandler.h"
#import "SMUtils.h"
#import "SMNotificationCellDelegate.h"
#import "SMNotificationsFooterCell.h"
#import "SMNotificationsHeaderCell.h"
#import "SMNotificationsViewController.h"
#import "SMNotificationTableViewCell.h"

FOUNDATION_EXPORT double SendManVersionNumber;
FOUNDATION_EXPORT const unsigned char SendManVersionString[];


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

#import <SendMan/JSONModel.h>
#import <SendMan/JSONModelClassProperty.h>
#import <SendMan/JSONModelError.h>
#import <SendMan/JSONKeyMapper.h>
#import <SendMan/JSONValueTransformer.h>
#import <SendMan/SMCategory.h>
#import <SendMan/SMData.h>
#import <SendMan/SMPropertyValue.h>
#import <SendMan/SMSDKEvent.h>
#import <SendMan/SMSession.h>
#import <SendMan/SendMan.h>
#import <SendMan/SMAPIHandler.h>
#import <SendMan/SMAuthHandler.h>
#import <SendMan/SMCategoriesHandler.h>
#import <SendMan/SMConfig.h>
#import <SendMan/SMDataCollector.h>
#import <SendMan/SMDataEnricher.h>
#import <SendMan/SMLifecycleHandler.h>
#import <SendMan/SMLog.h>
#import <SendMan/SMSessionManager.h>
#import <SendMan/SMUtils.h>
#import <SendMan/SMNotificationCellDelegate.h>
#import <SendMan/SMNotificationsFooterCell.h>
#import <SendMan/SMNotificationsHeaderCell.h>
#import <SendMan/SMNotificationsViewController.h>
#import <SendMan/SMNotificationTableViewCell.h>

FOUNDATION_EXPORT double SendManVersionNumber;
FOUNDATION_EXPORT const unsigned char SendManVersionString[];


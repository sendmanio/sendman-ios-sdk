//
//  SMLog.h
//  SendMan
//
//  Created by Avishay Sheba Harari on 27/07/2020.
//

#ifndef SMLog_h
#define SMLog_h

#define SMLOG(fmt, ...) NSLog(@"[SendMan] %@", [NSString stringWithFormat:(fmt), ##__VA_ARGS__])

#ifndef SENDMAN_DEBUG
#define SENDMAN_DEBUG 0
#endif

#ifndef SENDMAN_LOG
#if SENDMAN_DEBUG
#   define SENDMAN_LOG(fmt, ...) SMLOG(fmt, ##__VA_ARGS__)
#else
#   define SENDMAN_LOG(...)
#endif
#endif

#ifndef SENDMAN_LOG_ERRORS
#define SENDMAN_LOG_ERRORS 1
#endif

#ifndef SENDMAN_ERROR
#if SENDMAN_LOG_ERRORS
#   define SENDMAN_ERROR(fmt, ...) SMLOG(fmt, ##__VA_ARGS__)
#else
#   define SENDMAN_ERROR(...)
#endif
#endif


#endif /* SMLog_h */

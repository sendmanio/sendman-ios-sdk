//
//  SMLog.h
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

#ifndef SMLog_h
#define SMLog_h

#define SMLOG(fmt, ...) NSLog(@"[SendMan] %@", [NSString stringWithFormat:(fmt), ##__VA_ARGS__])

#ifndef SENDMAN_DEBUG
#define SENDMAN_DEBUG 1
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

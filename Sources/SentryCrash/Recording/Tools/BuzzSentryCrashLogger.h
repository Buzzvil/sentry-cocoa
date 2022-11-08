//
//  BuzzSentryCrashLogger.h
//
//  Created by Karl Stenerud on 11-06-25.
//
//  Copyright (c) 2011 Karl Stenerud. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall remain in place
// in this source code.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

/**
 * BuzzSentryCrashLogger
 * ========
 *
 * Prints log entries to the console consisting of:
 * - Level (Error, Warn, Info, Debug, Trace)
 * - File
 * - Line
 * - Function
 * - Message
 *
 * Allows setting the minimum logging level in the preprocessor.
 *
 * Works in C or Objective-C contexts, with or without ARC, using CLANG or GCC.
 *
 *
 * =====
 * USAGE
 * =====
 *
 * Set the log level in your "Preprocessor Macros" build setting. You may choose
 * TRACE, DEBUG, INFO, WARN, ERROR. If nothing is set, it defaults to ERROR.
 *
 * Example: BuzzSentryCrashLogger_Level=WARN
 *
 * Anything below the level specified for BuzzSentryCrashLogger_Level will not be
 * compiled or printed.
 *
 *
 * Next, include the header file:
 *
 * #include "BuzzSentryCrashLogger.h"
 *
 *
 * Next, call the logger functions from your code (using objective-c strings
 * in objective-C files and regular strings in regular C files):
 *
 * Code:
 *    BuzzSentryCrashLOG_ERROR(@"Some error message");
 *
 * Prints:
 *    2011-07-16 05:41:01.379 TestApp[4439:f803] ERROR: SomeClass.m (21):
 * -[SomeFunction]: Some error message
 *
 * Code:
 *    BuzzSentryCrashLOG_INFO(@"Info about %@", someObject);
 *
 * Prints:
 *    2011-07-16 05:44:05.239 TestApp[4473:f803] INFO : SomeClass.m (20):
 * -[SomeFunction]: Info about <NSObject: 0xb622840>
 *
 *
 * The "BASIC" versions of the macros behave exactly like NSLog() or printf(),
 * except they respect the BuzzSentryCrashLogger_Level setting:
 *
 * Code:
 *    BuzzSentryCrashLOGBASIC_ERROR(@"A basic log entry");
 *
 * Prints:
 *    2011-07-16 05:44:05.916 TestApp[4473:f803] A basic log entry
 *
 *
 * NOTE: In C files, use "" instead of @"" in the format field. Logging calls
 *       in C files do not print the NSLog preamble:
 *
 * Objective-C version:
 *    BuzzSentryCrashLOG_ERROR(@"Some error message");
 *
 *    2011-07-16 05:41:01.379 TestApp[4439:f803] ERROR: SomeClass.m (21):
 * -[SomeFunction]: Some error message
 *
 * C version:
 *    BuzzSentryCrashLOG_ERROR("Some error message");
 *
 *    ERROR: SomeClass.c (21): SomeFunction(): Some error message
 *
 *
 * =============
 * LOCAL LOGGING
 * =============
 *
 * You can control logging messages at the local file level using the
 * "BuzzSentryCrashLogger_LocalLevel" define. Note that it must be defined BEFORE
 * including BuzzSentryCrashLogger.h
 *
 * The BuzzSentryCrashLOG_XX() and BuzzSentryCrashLOGBASIC_XX() macros will print out
 * based on the LOWER of BuzzSentryCrashLogger_Level and
 * BuzzSentryCrashLogger_LocalLevel, so if BuzzSentryCrashLogger_Level is DEBUG and
 * BuzzSentryCrashLogger_LocalLevel is TRACE, it will print all the way down to the
 * trace level for the local file where BuzzSentryCrashLogger_LocalLevel was
 * defined, and to the debug level everywhere else.
 *
 * Example:
 *
 * // BuzzSentryCrashLogger_LocalLevel, if defined, MUST come BEFORE including
 * BuzzSentryCrashLogger.h #define BuzzSentryCrashLogger_LocalLevel TRACE #import
 * "BuzzSentryCrashLogger.h"
 *
 *
 * ===============
 * IMPORTANT NOTES
 * ===============
 *
 * The C logger changes its behavior depending on the value of the preprocessor
 * define BuzzSentryCrashLogger_CBufferSize.
 *
 * If BuzzSentryCrashLogger_CBufferSize is > 0, the C logger will behave in an
 * async-safe manner, calling write() instead of printf(). Any log messages that
 * exceed the length specified by BuzzSentryCrashLogger_CBufferSize will be
 * truncated.
 *
 * If BuzzSentryCrashLogger_CBufferSize == 0, the C logger will use printf(), and
 * there will be no limit on the log message length.
 *
 * BuzzSentryCrashLogger_CBufferSize can only be set as a preprocessor define, and
 * will default to 1024 if not specified during compilation.
 */

// ============================================================================
#pragma mark - (internal) -
// ============================================================================

#ifndef HDR_BuzzSentryCrashLogger_h
#    define HDR_BuzzSentryCrashLogger_h

#    ifdef __cplusplus
extern "C" {
#    endif

#    include <stdbool.h>

#    ifdef __OBJC__

#        import <CoreFoundation/CoreFoundation.h>

void i_sentrycrashlog_logObjC(
    const char *level, const char *file, int line, const char *function, CFStringRef fmt, ...);

void i_sentrycrashlog_logObjCBasic(CFStringRef fmt, ...);

#        define i_BuzzSentryCrashLOG_FULL(LEVEL, FILE, LINE, FUNCTION, FMT, ...)                       \
            i_sentrycrashlog_logObjC(                                                              \
                LEVEL, FILE, LINE, FUNCTION, (__bridge CFStringRef)FMT, ##__VA_ARGS__)
#        define i_BuzzSentryCrashLOG_BASIC(FMT, ...)                                                   \
            i_sentrycrashlog_logObjCBasic((__bridge CFStringRef)FMT, ##__VA_ARGS__)

#    else // __OBJC__

void i_sentrycrashlog_logC(
    const char *level, const char *file, int line, const char *function, const char *fmt, ...);

void i_sentrycrashlog_logCBasic(const char *fmt, ...);

#        define i_BuzzSentryCrashLOG_FULL i_sentrycrashlog_logC
#        define i_BuzzSentryCrashLOG_BASIC i_sentrycrashlog_logCBasic

#    endif // __OBJC__

/* Back up any existing defines by the same name */
#    ifdef BuzzSentryCrash_NONE
#        define BuzzSentryCrashLOG_BAK_NONE BuzzSentryCrash_NONE
#        undef BuzzSentryCrash_NONE
#    endif
#    ifdef ERROR
#        define BuzzSentryCrashLOG_BAK_ERROR ERROR
#        undef ERROR
#    endif
#    ifdef WARN
#        define BuzzSentryCrashLOG_BAK_WARN WARN
#        undef WARN
#    endif
#    ifdef INFO
#        define BuzzSentryCrashLOG_BAK_INFO INFO
#        undef INFO
#    endif
#    ifdef DEBUG
#        define BuzzSentryCrashLOG_BAK_DEBUG DEBUG
#        undef DEBUG
#    endif
#    ifdef TRACE
#        define BuzzSentryCrashLOG_BAK_TRACE TRACE
#        undef TRACE
#    endif

#    define BuzzSentryCrashLogger_Level_None 0
#    define BuzzSentryCrashLogger_Level_Error 10
#    define BuzzSentryCrashLogger_Level_Warn 20
#    define BuzzSentryCrashLogger_Level_Info 30
#    define BuzzSentryCrashLogger_Level_Debug 40
#    define BuzzSentryCrashLogger_Level_Trace 50

#    define BuzzSentryCrash_NONE BuzzSentryCrashLogger_Level_None
#    define ERROR BuzzSentryCrashLogger_Level_Error
#    define WARN BuzzSentryCrashLogger_Level_Warn
#    define INFO BuzzSentryCrashLogger_Level_Info
#    define DEBUG BuzzSentryCrashLogger_Level_Debug
#    define TRACE BuzzSentryCrashLogger_Level_Trace

#    ifndef BuzzSentryCrashLogger_Level
#        define BuzzSentryCrashLogger_Level BuzzSentryCrashLogger_Level_Error
#    endif

#    ifndef BuzzSentryCrashLogger_LocalLevel
#        define BuzzSentryCrashLogger_LocalLevel BuzzSentryCrashLogger_Level_None
#    endif

#    define a_BuzzSentryCrashLOG_FULL(LEVEL, FMT, ...)                                                 \
        i_BuzzSentryCrashLOG_FULL(LEVEL, __FILE__, __LINE__, __PRETTY_FUNCTION__, FMT, ##__VA_ARGS__)

// ============================================================================
#    pragma mark - API -
// ============================================================================

/** Set the filename to log to.
 *
 * @param filename The file to write to (NULL = write to stdout).
 *
 * @param overwrite If true, overwrite the log file.
 */
bool sentrycrashlog_setLogFilename(const char *filename, bool overwrite);

/** Clear the log file. */
bool sentrycrashlog_clearLogFile(void);

/** Tests if the logger would print at the specified level.
 *
 * @param LEVEL The level to test for. One of:
 *            BuzzSentryCrashLogger_Level_Error,
 *            BuzzSentryCrashLogger_Level_Warn,
 *            BuzzSentryCrashLogger_Level_Info,
 *            BuzzSentryCrashLogger_Level_Debug,
 *            BuzzSentryCrashLogger_Level_Trace,
 *
 * @return TRUE if the logger would print at the specified level.
 */
#    define BuzzSentryCrashLOG_PRINTS_AT_LEVEL(LEVEL)                                                  \
        (BuzzSentryCrashLogger_Level >= LEVEL || BuzzSentryCrashLogger_LocalLevel >= LEVEL)

/** Log a message regardless of the log settings.
 * Normal version prints out full context. Basic version prints directly.
 *
 * @param FMT The format specifier, followed by its arguments.
 */
#    define BuzzSentryCrashLOG_ALWAYS(FMT, ...) a_BuzzSentryCrashLOG_FULL("FORCE", FMT, ##__VA_ARGS__)
#    define BuzzSentryCrashLOGBASIC_ALWAYS(FMT, ...) i_BuzzSentryCrashLOG_BASIC(FMT, ##__VA_ARGS__)

/** Log an error.
 * Normal version prints out full context. Basic version prints directly.
 *
 * @param FMT The format specifier, followed by its arguments.
 */
#    if BuzzSentryCrashLOG_PRINTS_AT_LEVEL(BuzzSentryCrashLogger_Level_Error)
#        define BuzzSentryCrashLOG_ERROR(FMT, ...) a_BuzzSentryCrashLOG_FULL("ERROR", FMT, ##__VA_ARGS__)
#        define BuzzSentryCrashLOGBASIC_ERROR(FMT, ...) i_BuzzSentryCrashLOG_BASIC(FMT, ##__VA_ARGS__)
#    else
#        define BuzzSentryCrashLOG_ERROR(FMT, ...)
#        define BuzzSentryCrashLOGBASIC_ERROR(FMT, ...)
#    endif

/** Log a warning.
 * Normal version prints out full context. Basic version prints directly.
 *
 * @param FMT The format specifier, followed by its arguments.
 */
#    if BuzzSentryCrashLOG_PRINTS_AT_LEVEL(BuzzSentryCrashLogger_Level_Warn)
#        define BuzzSentryCrashLOG_WARN(FMT, ...) a_BuzzSentryCrashLOG_FULL("WARN ", FMT, ##__VA_ARGS__)
#        define BuzzSentryCrashLOGBASIC_WARN(FMT, ...) i_BuzzSentryCrashLOG_BASIC(FMT, ##__VA_ARGS__)
#    else
#        define BuzzSentryCrashLOG_WARN(FMT, ...)
#        define BuzzSentryCrashLOGBASIC_WARN(FMT, ...)
#    endif

/** Log an info message.
 * Normal version prints out full context. Basic version prints directly.
 *
 * @param FMT The format specifier, followed by its arguments.
 */
#    if BuzzSentryCrashLOG_PRINTS_AT_LEVEL(BuzzSentryCrashLogger_Level_Info)
#        define BuzzSentryCrashLOG_INFO(FMT, ...) a_BuzzSentryCrashLOG_FULL("INFO ", FMT, ##__VA_ARGS__)
#        define BuzzSentryCrashLOGBASIC_INFO(FMT, ...) i_BuzzSentryCrashLOG_BASIC(FMT, ##__VA_ARGS__)
#    else
#        define BuzzSentryCrashLOG_INFO(FMT, ...)
#        define BuzzSentryCrashLOGBASIC_INFO(FMT, ...)
#    endif

/** Log a debug message.
 * Normal version prints out full context. Basic version prints directly.
 *
 * @param FMT The format specifier, followed by its arguments.
 */
#    if BuzzSentryCrashLOG_PRINTS_AT_LEVEL(BuzzSentryCrashLogger_Level_Debug)
#        define BuzzSentryCrashLOG_DEBUG(FMT, ...) a_BuzzSentryCrashLOG_FULL("DEBUG", FMT, ##__VA_ARGS__)
#        define BuzzSentryCrashLOGBASIC_DEBUG(FMT, ...) i_BuzzSentryCrashLOG_BASIC(FMT, ##__VA_ARGS__)
#    else
#        define BuzzSentryCrashLOG_DEBUG(FMT, ...)
#        define BuzzSentryCrashLOGBASIC_DEBUG(FMT, ...)
#    endif

/** Log a trace message.
 * Normal version prints out full context. Basic version prints directly.
 *
 * @param FMT The format specifier, followed by its arguments.
 */
#    if BuzzSentryCrashLOG_PRINTS_AT_LEVEL(BuzzSentryCrashLogger_Level_Trace)
#        define BuzzSentryCrashLOG_TRACE(FMT, ...) a_BuzzSentryCrashLOG_FULL("TRACE", FMT, ##__VA_ARGS__)
#        define BuzzSentryCrashLOGBASIC_TRACE(FMT, ...) i_BuzzSentryCrashLOG_BASIC(FMT, ##__VA_ARGS__)
#    else
#        define BuzzSentryCrashLOG_TRACE(FMT, ...)
#        define BuzzSentryCrashLOGBASIC_TRACE(FMT, ...)
#    endif

// ============================================================================
#    pragma mark - (internal) -
// ============================================================================

/* Put everything back to the way we found it. */
#    undef ERROR
#    ifdef BuzzSentryCrashLOG_BAK_ERROR
#        define ERROR BuzzSentryCrashLOG_BAK_ERROR
#        undef BuzzSentryCrashLOG_BAK_ERROR
#    endif
#    undef WARNING
#    ifdef BuzzSentryCrashLOG_BAK_WARN
#        define WARNING BuzzSentryCrashLOG_BAK_WARN
#        undef BuzzSentryCrashLOG_BAK_WARN
#    endif
#    undef INFO
#    ifdef BuzzSentryCrashLOG_BAK_INFO
#        define INFO BuzzSentryCrashLOG_BAK_INFO
#        undef BuzzSentryCrashLOG_BAK_INFO
#    endif
#    undef DEBUG
#    ifdef BuzzSentryCrashLOG_BAK_DEBUG
#        define DEBUG BuzzSentryCrashLOG_BAK_DEBUG
#        undef BuzzSentryCrashLOG_BAK_DEBUG
#    endif
#    undef TRACE
#    ifdef BuzzSentryCrashLOG_BAK_TRACE
#        define TRACE BuzzSentryCrashLOG_BAK_TRACE
#        undef BuzzSentryCrashLOG_BAK_TRACE
#    endif

#    ifdef __cplusplus
}
#    endif

#endif // HDR_BuzzSentryCrashLogger_h

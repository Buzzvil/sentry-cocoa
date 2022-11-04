#import "BuzzSentryCrashMachineContext.h"
#import "BuzzSentryCrashStackCursor.h"
#include "BuzzSentryCrashThread.h"
#import "BuzzSentryDefines.h"
#import <Foundation/Foundation.h>

@class BuzzSentryStacktrace, BuzzSentryFrameRemover, BuzzSentryCrashStackEntryMapper;

NS_ASSUME_NONNULL_BEGIN

/** Uses BuzzSentryCrash internally to retrieve the stacktrace.
 */
@interface BuzzSentryStacktraceBuilder : NSObject
SENTRY_NO_INIT

- (id)initWithCrashStackEntryMapper:(BuzzSentryCrashStackEntryMapper *)crashStackEntryMapper;

/**
 * Builds the stacktrace for the current thread removing frames from the BuzzSentrySDK until frames from
 * a different package are found. When including Sentry via the Swift Package Manager the package is
 * the same as the application that includes Sentry. In this case the full stacktrace is returned
 * without skipping frames.
 */
- (BuzzSentryStacktrace *)buildStacktraceForCurrentThread;

/**
 * Builds the stacktrace for given thread removing frames from the BuzzSentrySDK until frames from
 * a different package are found. When including Sentry via the Swift Package Manager the package is
 * the same as the application that includes Sentry. In this case the full stacktrace is returned
 * without skipping frames.
 */
- (BuzzSentryStacktrace *)buildStacktraceForThread:(BuzzSentryCrashThread)thread
                                       context:(struct BuzzSentryCrashMachineContext *)context;

- (BuzzSentryStacktrace *)buildStackTraceFromStackEntries:(BuzzSentryCrashStackEntry *)entries
                                               amount:(unsigned int)amount;
@end

NS_ASSUME_NONNULL_END

#import "BuzzSentryCrashMachineContextWrapper.h"
#import "BuzzSentryDefines.h"
#import <Foundation/Foundation.h>

@class SentryThread, BuzzSentryStacktraceBuilder;

NS_ASSUME_NONNULL_BEGIN

@interface BuzzSentryThreadInspector : NSObject
SENTRY_NO_INIT

- (id)initWithStacktraceBuilder:(BuzzSentryStacktraceBuilder *)stacktraceBuilder
       andMachineContextWrapper:(id<BuzzSentryCrashMachineContextWrapper>)machineContextWrapper;

/**
 * Gets current threads with the stacktrace only for the current thread. Frames from the BuzzSentrySDK
 * are not included. For more details checkout BuzzSentryStacktraceBuilder.
 * The first thread in the result is always the main thread.
 */
- (NSArray<SentryThread *> *)getCurrentThreads;

/**
 * Gets current threads with stacktrace,
 * this will pause every thread in order to be possible to retrieve this information.
 * Frames from the BuzzSentrySDK are not included. For more details checkout BuzzSentryStacktraceBuilder.
 * The first thread in the result is always the main thread.
 */
- (NSArray<SentryThread *> *)getCurrentThreadsWithStackTrace;

@end

NS_ASSUME_NONNULL_END

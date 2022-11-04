#import "BuzzSentryCompiler.h"
#import "BuzzSentryProfilingConditionals.h"
#import "BuzzSentrySpan.h"
#import <Foundation/Foundation.h>

#if SENTRY_HAS_UIKIT
@class BuzzSentryFramesTracker;
#endif // SENTRY_HAS_UIKIT
@class BuzzSentryHub;
@class BuzzSentryProfilesSamplerDecision;
@class BuzzSentryScreenFrames;
@class BuzzSentryEnvelope;
@class BuzzSentrySpanId;
@class BuzzSentryTransaction;

#if SENTRY_TARGET_PROFILING_SUPPORTED

typedef NS_ENUM(NSUInteger, BuzzSentryProfilerTruncationReason) {
    BuzzSentryProfilerTruncationReasonNormal,
    BuzzSentryProfilerTruncationReasonTimeout,
    BuzzSentryProfilerTruncationReasonAppMovedToBackground,
};

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT const int kBuzzSentryProfilerFrequencyHz;
FOUNDATION_EXPORT NSString *const kTestStringConst;

SENTRY_EXTERN_C_BEGIN

/*
 * Parses a symbol that is returned from `backtrace_symbols()`, which encodes information
 * like the frame index, image name, function name, and offset in a single string. e.g.
 * For the input:
 * 2   UIKitCore                           0x00000001850d97ac -[UIFieldEditor
 * _fullContentInsetsFromFonts] + 160 This function would return: -[UIFieldEditor
 * _fullContentInsetsFromFonts]
 *
 * If the format does not match the expected format, this returns the input string.
 */
NSString *parseBacktraceSymbolsFunctionName(const char *symbol);

NSString *profilerTruncationReasonName(BuzzSentryProfilerTruncationReason reason);

SENTRY_EXTERN_C_END

@interface BuzzSentryProfiler : NSObject

/**
 * Start the profiler, if it isn't already running, for the span with the provided ID. If it's
 * already running, it will track the new span as well.
 */
+ (void)startForSpanID:(BuzzSentrySpanId *)spanID hub:(BuzzSentryHub *)hub;

/**
 * Report that a span ended to the profiler so it can update bookkeeping and if it was the last
 * concurrent span being profiled, stops the profiler.
 */
+ (void)stopProfilingSpan:(id<BuzzSentrySpan>)span;

/**
 * Certain transactions may be dropped by the SDK at the time they are ended, when we've already
 * been tracking them for profiling. This allows them to be removed from bookkeeping and finish
 * profile if necessary.
 */
+ (void)dropTransaction:(BuzzSentryTransaction *)transaction;
;

/**
 * After the SDK creates a transaction for a span, link it to this profile. If it was the last
 * concurrent span being profiled, capture an envelope with the profile data and clean up the
 * profiler.
 */
+ (void)linkTransaction:(BuzzSentryTransaction *)transaction;

+ (BOOL)isRunning;

@end

NS_ASSUME_NONNULL_END

#endif // SENTRY_TARGET_PROFILING_SUPPORTED
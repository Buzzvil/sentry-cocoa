#import "BuzzSentryDefines.h"
#import "BuzzSentryProfilingConditionals.h"

@class BuzzSentryOptions, BuzzSentryDisplayLinkWrapper, BuzzSentryScreenFrames;

NS_ASSUME_NONNULL_BEGIN

#if SENTRY_HAS_UIKIT

@class BuzzSentryTracer;

/**
 * Tracks total, frozen and slow frames for iOS, tvOS, and Mac Catalyst.
 */
@interface BuzzSentryFramesTracker : NSObject
SENTRY_NO_INIT

+ (instancetype)sharedInstance;

@property (nonatomic, assign, readonly) BuzzSentryScreenFrames *currentFrames;
@property (nonatomic, assign, readonly) BOOL isRunning;

#    if SENTRY_TARGET_PROFILING_SUPPORTED
/** Remove previously recorded timestamps in preparation for a later profiled transaction. */
- (void)resetProfilingTimestamps;
#    endif // SENTRY_TARGET_PROFILING_SUPPORTED

- (void)start;
- (void)stop;

@end

#endif

NS_ASSUME_NONNULL_END

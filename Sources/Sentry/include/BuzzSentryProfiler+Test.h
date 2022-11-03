#import "BuzzSentryProfiler.h"
#import "BuzzSentryProfilingConditionals.h"

#if SENTRY_TARGET_PROFILING_SUPPORTED
@interface
BuzzSentryProfiler (SentryTest)

+ (void)timeoutAbort;

@end
#endif // SENTRY_TARGET_PROFILING_SUPPORTED

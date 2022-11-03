#import "BuzzSentryLog.h"
#import <Sentry/Sentry.h>

NS_ASSUME_NONNULL_BEGIN

@class BuzzSentryLogOutput;

@interface
BuzzSentryLog (TestInit)

/** Internal and only needed for testing. */
+ (void)setLogOutput:(nullable BuzzSentryLogOutput *)output;

/** Internal and only needed for testing. */
+ (BuzzSentryLogOutput *)logOutput;

/** Internal and only needed for testing. */
+ (BOOL)isDebug;

/** Internal and only needed for testing. */
+ (SentryLevel)diagnosticLevel;

@end

NS_ASSUME_NONNULL_END

#import "BuzzSentryLog.h"
#import "BuzzSentryLevelMapper.h"
#import "BuzzSentryLogOutput.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BuzzSentryLog

/**
 * Enable per default to log initialization errors.
 */
static BOOL isDebug = YES;
static BuzzSentryLevel diagnosticLevel = kBuzzSentryLevelError;
static BuzzSentryLogOutput *logOutput;

+ (void)configure:(BOOL)debug diagnosticLevel:(BuzzSentryLevel)level
{
    isDebug = debug;
    diagnosticLevel = level;
}

+ (void)logWithMessage:(NSString *)message andLevel:(BuzzSentryLevel)level
{
    if (nil == logOutput) {
        logOutput = [[BuzzSentryLogOutput alloc] init];
    }

    if (isDebug && level != kBuzzSentryLevelNone && level >= diagnosticLevel) {
        [logOutput log:[NSString stringWithFormat:@"[Sentry] [%@] %@", nameForBuzzSentryLevel(level),
                                 message]];
    }
}

// Internal and only needed for testing.
+ (void)setLogOutput:(BuzzSentryLogOutput *)output
{
    logOutput = output;
}

// Internal and only needed for testing.
+ (BuzzSentryLogOutput *)logOutput
{
    return logOutput;
}

// Internal and only needed for testing.
+ (BOOL)isDebug
{
    return isDebug;
}

// Internal and only needed for testing.
+ (BuzzSentryLevel)diagnosticLevel
{
    return diagnosticLevel;
}

@end

NS_ASSUME_NONNULL_END

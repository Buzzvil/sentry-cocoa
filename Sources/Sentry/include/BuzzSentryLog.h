#import "BuzzSentryDefines.h"

@class BuzzSentryLogOutput;

NS_ASSUME_NONNULL_BEGIN

@interface BuzzSentryLog : NSObject
SENTRY_NO_INIT

+ (void)configure:(BOOL)debug diagnosticLevel:(BuzzSentryLevel)level;

+ (void)logWithMessage:(NSString *)message andLevel:(BuzzSentryLevel)level;

@end

NS_ASSUME_NONNULL_END
#define SENTRY_LOG(_SENTRY_LOG_LEVEL, ...)                                                         \
    [BuzzSentryLog logWithMessage:[NSString stringWithFormat:@"[%@:%d] %@",                            \
                                        [[[NSString stringWithUTF8String:__FILE__]                 \
                                            lastPathComponent] stringByDeletingPathExtension],     \
                                        __LINE__, [NSString stringWithFormat:__VA_ARGS__]]         \
                     andLevel:_SENTRY_LOG_LEVEL]
#define SENTRY_LOG_DEBUG(...) SENTRY_LOG(kBuzzSentryLevelDebug, __VA_ARGS__)
#define SENTRY_LOG_INFO(...) SENTRY_LOG(kBuzzSentryLevelInfo, __VA_ARGS__)
#define SENTRY_LOG_WARN(...) SENTRY_LOG(kBuzzSentryLevelWarning, __VA_ARGS__)
#define SENTRY_LOG_ERROR(...) SENTRY_LOG(kBuzzSentryLevelError, __VA_ARGS__)
#define SENTRY_LOG_FATAL(...) SENTRY_LOG(kBuzzSentryLevelFatal, __VA_ARGS__)

/**
 * If `errno` is set to a non-zero value after `statement` finishes executing,
 * the error value is logged, and the original return value of `statement` is
 * returned.
 */
#define SENTRY_LOG_ERRNO(statement)                                                                \
    ({                                                                                             \
        errno = 0;                                                                                 \
        const auto __log_rv = (statement);                                                         \
        const int __log_errnum = errno;                                                            \
        if (__log_errnum != 0) {                                                                   \
            SENTRY_LOG_ERROR(@"%s failed with code: %d, description: %s", #statement,              \
                __log_errnum, strerror(__log_errnum));                                             \
        }                                                                                          \
        __log_rv;                                                                                  \
    })

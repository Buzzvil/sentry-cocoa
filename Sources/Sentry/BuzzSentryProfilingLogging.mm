#include "BuzzSentryProfilingLogging.hpp"

#import "BuzzSentryLog.h"

namespace sentry {
namespace profiling {
    namespace {
        BuzzSentryLevel
        sentryLevelFromLogLevel(LogLevel level)
        {
            switch (level) {
            case LogLevel::None:
                return kBuzzSentryLevelNone;
            case LogLevel::Debug:
                return kBuzzSentryLevelDebug;
            case LogLevel::Info:
                return kBuzzSentryLevelInfo;
            case LogLevel::Warning:
                return kBuzzSentryLevelWarning;
            case LogLevel::Error:
                return kBuzzSentryLevelError;
            case LogLevel::Fatal:
                return kBuzzSentryLevelFatal;
            }
        }
    }

    void
    log(LogLevel level, const char *fmt, ...)
    {
        if (fmt == nullptr) {
            return;
        }
        va_list args;
        va_start(args, fmt);
        const auto fmtStr = [[NSString alloc] initWithUTF8String:fmt];
        const auto msgStr = [[NSString alloc] initWithFormat:fmtStr arguments:args];
        va_end(args);
        [BuzzSentryLog logWithMessage:msgStr andLevel:sentryLevelFromLogLevel(level)];
    }

} // namespace profiling
} // namespace sentry

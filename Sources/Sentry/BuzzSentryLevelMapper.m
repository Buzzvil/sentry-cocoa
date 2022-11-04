#import "BuzzSentryLevelMapper.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const kBuzzSentryLevelNameNone = @"none";
NSString *const kBuzzSentryLevelNameDebug = @"debug";
NSString *const kBuzzSentryLevelNameInfo = @"info";
NSString *const kBuzzSentryLevelNameWarning = @"warning";
NSString *const kBuzzSentryLevelNameError = @"error";
NSString *const kBuzzSentryLevelNameFatal = @"fatal";

BuzzSentryLevel
sentryLevelForString(NSString *string)
{
    if ([string isEqualToString:kBuzzSentryLevelNameNone]) {
        return kBuzzSentryLevelNone;
    }
    if ([string isEqualToString:kBuzzSentryLevelNameDebug]) {
        return kBuzzSentryLevelDebug;
    }
    if ([string isEqualToString:kBuzzSentryLevelNameInfo]) {
        return kBuzzSentryLevelInfo;
    }
    if ([string isEqualToString:kBuzzSentryLevelNameWarning]) {
        return kBuzzSentryLevelWarning;
    }
    if ([string isEqualToString:kBuzzSentryLevelNameError]) {
        return kBuzzSentryLevelError;
    }
    if ([string isEqualToString:kBuzzSentryLevelNameFatal]) {
        return kBuzzSentryLevelFatal;
    }

    // Default is error, see https://develop.sentry.dev/sdk/event-payloads/#optional-attributes
    return kBuzzSentryLevelError;
}

NSString *
nameForBuzzSentryLevel(BuzzSentryLevel level)
{
    switch (level) {
    case kBuzzSentryLevelNone:
        return kBuzzSentryLevelNameNone;
    case kBuzzSentryLevelDebug:
        return kBuzzSentryLevelNameDebug;
    case kBuzzSentryLevelInfo:
        return kBuzzSentryLevelNameInfo;
    case kBuzzSentryLevelWarning:
        return kBuzzSentryLevelNameWarning;
    case kBuzzSentryLevelError:
        return kBuzzSentryLevelNameError;
    case kBuzzSentryLevelFatal:
        return kBuzzSentryLevelNameFatal;
    }
}

NS_ASSUME_NONNULL_END

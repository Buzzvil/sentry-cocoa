#import "BuzzSentryDefines.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const kBuzzSentryLevelNameNone;
FOUNDATION_EXPORT NSString *const kBuzzSentryLevelNameDebug;
FOUNDATION_EXPORT NSString *const kBuzzSentryLevelNameInfo;
FOUNDATION_EXPORT NSString *const kBuzzSentryLevelNameWarning;
FOUNDATION_EXPORT NSString *const kBuzzSentryLevelNameError;
FOUNDATION_EXPORT NSString *const kBuzzSentryLevelNameFatal;

/**
 * Maps a string to a BuzzSentryLevel. If the passed string doesn't match any level this defaults to
 * the 'error' level. See https://develop.sentry.dev/sdk/event-payloads/#optional-attributes
 */
BuzzSentryLevel sentryLevelForString(NSString *string);

NSString *nameForBuzzSentryLevel(BuzzSentryLevel level);

NS_ASSUME_NONNULL_END

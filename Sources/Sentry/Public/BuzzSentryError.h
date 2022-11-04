#import <BuzzSentry/BuzzSentryDefines.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BuzzSentryError) {
    kBuzzSentryErrorUnknownError = -1,
    kBuzzSentryErrorInvalidDsnError = 100,
    kBuzzSentryErrorSentryCrashNotInstalledError = 101,
    kBuzzSentryErrorInvalidCrashReportError = 102,
    kBuzzSentryErrorCompressionError = 103,
    kBuzzSentryErrorJsonConversionError = 104,
    kBuzzSentryErrorCouldNotFindDirectory = 105,
    kBuzzSentryErrorRequestError = 106,
    kBuzzSentryErrorEventNotSent = 107,
};

SENTRY_EXTERN NSError *_Nullable NSErrorFromBuzzSentryError(BuzzSentryError error, NSString *description);

SENTRY_EXTERN NSString *const BuzzSentryErrorDomain;

NS_ASSUME_NONNULL_END

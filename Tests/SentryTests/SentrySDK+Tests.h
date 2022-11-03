#import <Sentry/Sentry.h>

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentrySDK (Tests)

+ (void)setCurrentHub:(nullable BuzzSentryHub *)hub;

+ (void)captureEnvelope:(BuzzSentryEnvelope *)envelope;

+ (void)storeEnvelope:(BuzzSentryEnvelope *)envelope;

@end

NS_ASSUME_NONNULL_END

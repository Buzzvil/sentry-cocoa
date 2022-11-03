#import <Sentry/Sentry.h>

NS_ASSUME_NONNULL_BEGIN

@interface
SentrySDK (Tests)

+ (void)setCurrentHub:(nullable SentryHub *)hub;

+ (void)captureEnvelope:(BuzzSentryEnvelope *)envelope;

+ (void)storeEnvelope:(BuzzSentryEnvelope *)envelope;

@end

NS_ASSUME_NONNULL_END

#import <Sentry/Sentry.h>

NS_ASSUME_NONNULL_BEGIN

/** Expose the internal test init for testing. */
@interface
BuzzSentryHub (TestInit)

- (instancetype)initWithClient:(BuzzSentryClient *_Nullable)client
                      andScope:(BuzzSentryScope *_Nullable)scope
               andCrashWrapper:(BuzzSentryCrashWrapper *)crashAdapter
        andCurrentDateProvider:(id<SentryCurrentDateProvider>)currentDateProvider;

@end

NS_ASSUME_NONNULL_END

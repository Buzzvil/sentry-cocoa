#import "SentryDefines.h"

NS_ASSUME_NONNULL_BEGIN

@class BuzzSentrySwizzleWrapper;

@interface BuzzSentryBreadcrumbTracker : NSObject
SENTRY_NO_INIT

- (instancetype)initWithSwizzleWrapper:(BuzzSentrySwizzleWrapper *)swizzleWrapper;

- (void)start;
- (void)startSwizzle;
- (void)stop;

@end

NS_ASSUME_NONNULL_END

#import "SentryDefines.h"

NS_ASSUME_NONNULL_BEGIN

@class BuzzSentrySwizzleWrapper, BuzzSentryDispatchQueueWrapper;

@interface BuzzSentryUIEventTracker : NSObject
SENTRY_NO_INIT

#if SENTRY_HAS_UIKIT

- (instancetype)initWithSwizzleWrapper:(BuzzSentrySwizzleWrapper *)swizzleWrapper
                  dispatchQueueWrapper:(BuzzSentryDispatchQueueWrapper *)dispatchQueueWrapper
                           idleTimeout:(NSTimeInterval)idleTimeout;

- (void)start;
- (void)stop;

#endif

+ (BOOL)isUIEventOperation:(NSString *)operation;

@end

NS_ASSUME_NONNULL_END

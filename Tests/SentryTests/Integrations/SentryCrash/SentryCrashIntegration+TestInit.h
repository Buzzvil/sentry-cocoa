#import "SentryCrashIntegration.h"
#import "BuzzSentryDispatchQueueWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@interface
SentryCrashIntegration (TestInit)

- (instancetype)initWithCrashAdapter:(SentryCrashWrapper *)crashWrapper
             andDispatchQueueWrapper:(BuzzSentryDispatchQueueWrapper *)dispatchQueueWrapper;

@end

NS_ASSUME_NONNULL_END

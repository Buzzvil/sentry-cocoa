#import "BuzzSentryCrashIntegration.h"
#import "BuzzSentryDispatchQueueWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentryCrashIntegration (TestInit)

- (instancetype)initWithCrashAdapter:(BuzzSentryCrashWrapper *)crashWrapper
             andDispatchQueueWrapper:(BuzzSentryDispatchQueueWrapper *)dispatchQueueWrapper;

@end

NS_ASSUME_NONNULL_END
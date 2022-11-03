#import "SentryDefines.h"

@class BuzzSentryOptions, SentryCrashWrapper, SentryAppState, SentryFileManager, SentryAppStateManager;

NS_ASSUME_NONNULL_BEGIN

@interface SentryOutOfMemoryLogic : NSObject
SENTRY_NO_INIT

- (instancetype)initWithOptions:(BuzzSentryOptions *)options
                   crashAdapter:(SentryCrashWrapper *)crashAdapter
                appStateManager:(SentryAppStateManager *)appStateManager;

- (BOOL)isOOM;

@end

NS_ASSUME_NONNULL_END

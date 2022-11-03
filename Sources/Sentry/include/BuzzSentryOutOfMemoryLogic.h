#import "SentryDefines.h"

@class BuzzSentryOptions, BuzzSentryCrashWrapper, SentryAppState, SentryFileManager, SentryAppStateManager;

NS_ASSUME_NONNULL_BEGIN

@interface BuzzSentryOutOfMemoryLogic : NSObject
SENTRY_NO_INIT

- (instancetype)initWithOptions:(BuzzSentryOptions *)options
                   crashAdapter:(BuzzSentryCrashWrapper *)crashAdapter
                appStateManager:(SentryAppStateManager *)appStateManager;

- (BOOL)isOOM;

@end

NS_ASSUME_NONNULL_END

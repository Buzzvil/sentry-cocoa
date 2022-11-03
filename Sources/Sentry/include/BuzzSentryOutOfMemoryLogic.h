#import "BuzzSentryDefines.h"

@class BuzzSentryOptions, BuzzSentryCrashWrapper, BuzzSentryAppState, BuzzSentryFileManager, BuzzSentryAppStateManager;

NS_ASSUME_NONNULL_BEGIN

@interface BuzzSentryOutOfMemoryLogic : NSObject
SENTRY_NO_INIT

- (instancetype)initWithOptions:(BuzzSentryOptions *)options
                   crashAdapter:(BuzzSentryCrashWrapper *)crashAdapter
                appStateManager:(BuzzSentryAppStateManager *)appStateManager;

- (BOOL)isOOM;

@end

NS_ASSUME_NONNULL_END

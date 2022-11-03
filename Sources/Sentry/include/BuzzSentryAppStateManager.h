#import "BuzzSentryCurrentDateProvider.h"
#import "SentryDefines.h"

@class BuzzSentryOptions, BuzzSentryCrashWrapper, BuzzSentryAppState, BuzzSentryFileManager, SentrySysctl,
    BuzzSentryDispatchQueueWrapper;

NS_ASSUME_NONNULL_BEGIN

@interface BuzzSentryAppStateManager : NSObject
SENTRY_NO_INIT

- (instancetype)initWithOptions:(BuzzSentryOptions *)options
                   crashWrapper:(BuzzSentryCrashWrapper *)crashWrapper
                    fileManager:(BuzzSentryFileManager *)fileManager
            currentDateProvider:(id<BuzzSentryCurrentDateProvider>)currentDateProvider
                         sysctl:(SentrySysctl *)sysctl
           dispatchQueueWrapper:(BuzzSentryDispatchQueueWrapper *)dispatchQueueWrapper;

#if SENTRY_HAS_UIKIT

- (void)start;
- (void)stop;

/**
 * Builds the current app state.
 *
 * @discussion The systemBootTimestamp is calculated by taking the current time and substracting
 * NSProcesInfo.systemUptime.  NSProcesInfo.systemUptime returns the amount of time the system has
 * been awake since the last time it was restarted. This means This is a good enough approximation
 * about the timestamp the system booted.
 */
- (BuzzSentryAppState *)buildCurrentAppState;

- (BuzzSentryAppState *)loadPreviousAppState;

- (void)storeCurrentAppState;

- (void)deleteAppState;

- (void)updateAppState:(void (^)(BuzzSentryAppState *))block;

#endif

@end

NS_ASSUME_NONNULL_END

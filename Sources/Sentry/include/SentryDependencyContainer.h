#import "SentryDefines.h"
#import "SentryFileManager.h"
#import "BuzzSentryRandom.h"

@class SentryAppStateManager, SentryCrashWrapper, SentryThreadWrapper, SentrySwizzleWrapper,
    BuzzSentryDispatchQueueWrapper, SentryDebugImageProvider, BuzzSentryANRTracker,
    SentryNSNotificationCenterWrapper;

#if SENTRY_HAS_UIKIT
@class BuzzSentryScreenshot, BuzzSentryUIApplication, BuzzSentryViewHierarchy;
#endif

NS_ASSUME_NONNULL_BEGIN

@interface SentryDependencyContainer : NSObject
SENTRY_NO_INIT

+ (instancetype)sharedInstance;

/**
 * Set all dependencies to nil for testing purposes.
 */
+ (void)reset;

@property (nonatomic, strong) SentryFileManager *fileManager;
@property (nonatomic, strong) SentryAppStateManager *appStateManager;
@property (nonatomic, strong) SentryCrashWrapper *crashWrapper;
@property (nonatomic, strong) SentryThreadWrapper *threadWrapper;
@property (nonatomic, strong) id<BuzzSentryRandom> random;
@property (nonatomic, strong) SentrySwizzleWrapper *swizzleWrapper;
@property (nonatomic, strong) BuzzSentryDispatchQueueWrapper *dispatchQueueWrapper;
@property (nonatomic, strong) SentryNSNotificationCenterWrapper *notificationCenterWrapper;
@property (nonatomic, strong) SentryDebugImageProvider *debugImageProvider;
@property (nonatomic, strong) BuzzSentryANRTracker *anrTracker;

#if SENTRY_HAS_UIKIT
@property (nonatomic, strong) BuzzSentryScreenshot *screenshot;
@property (nonatomic, strong) BuzzSentryViewHierarchy *viewHierarchy;
@property (nonatomic, strong) BuzzSentryUIApplication *application;
#endif

- (BuzzSentryANRTracker *)getANRTracker:(NSTimeInterval)timeout;

@end

NS_ASSUME_NONNULL_END

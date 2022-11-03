#import "SentryDefines.h"
#import "BuzzSentryFileManager.h"
#import "BuzzSentryRandom.h"

@class BuzzSentryAppStateManager, BuzzSentryCrashWrapper, SentryThreadWrapper, BuzzSentrySwizzleWrapper,
    BuzzSentryDispatchQueueWrapper, BuzzSentryDebugImageProvider, BuzzSentryANRTracker,
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

@property (nonatomic, strong) BuzzSentryFileManager *fileManager;
@property (nonatomic, strong) BuzzSentryAppStateManager *appStateManager;
@property (nonatomic, strong) BuzzSentryCrashWrapper *crashWrapper;
@property (nonatomic, strong) SentryThreadWrapper *threadWrapper;
@property (nonatomic, strong) id<BuzzSentryRandom> random;
@property (nonatomic, strong) BuzzSentrySwizzleWrapper *swizzleWrapper;
@property (nonatomic, strong) BuzzSentryDispatchQueueWrapper *dispatchQueueWrapper;
@property (nonatomic, strong) SentryNSNotificationCenterWrapper *notificationCenterWrapper;
@property (nonatomic, strong) BuzzSentryDebugImageProvider *debugImageProvider;
@property (nonatomic, strong) BuzzSentryANRTracker *anrTracker;

#if SENTRY_HAS_UIKIT
@property (nonatomic, strong) BuzzSentryScreenshot *screenshot;
@property (nonatomic, strong) BuzzSentryViewHierarchy *viewHierarchy;
@property (nonatomic, strong) BuzzSentryUIApplication *application;
#endif

- (BuzzSentryANRTracker *)getANRTracker:(NSTimeInterval)timeout;

@end

NS_ASSUME_NONNULL_END

#import "BuzzSentryDefines.h"

@class BuzzSentryOptions, BuzzSentryOutOfMemoryLogic, BuzzSentryDispatchQueueWrapper, BuzzSentryAppStateManager,
    BuzzSentryFileManager;

NS_ASSUME_NONNULL_BEGIN

static NSString *const BuzzSentryOutOfMemoryExceptionType = @"OutOfMemory";
static NSString *const BuzzSentryOutOfMemoryExceptionValue
    = @"The OS most likely terminated your app because it overused RAM.";
static NSString *const BuzzSentryOutOfMemoryMechanismType = @"out_of_memory";

/**
 * Detect OOMs based on heuristics described in a blog post:
 * https://engineering.fb.com/2015/08/24/ios/reducing-fooms-in-the-facebook-ios-app/ If a OOM is
 * detected, the SDK sends it as crash event. Only works for iOS, tvOS and macCatalyst.
 */
@interface BuzzSentryOutOfMemoryTracker : NSObject
SENTRY_NO_INIT

- (instancetype)initWithOptions:(BuzzSentryOptions *)options
               outOfMemoryLogic:(BuzzSentryOutOfMemoryLogic *)outOfMemoryLogic
                appStateManager:(BuzzSentryAppStateManager *)appStateManager
           dispatchQueueWrapper:(BuzzSentryDispatchQueueWrapper *)dispatchQueueWrapper
                    fileManager:(BuzzSentryFileManager *)fileManager;

- (void)start;
- (void)stop;

@end

NS_ASSUME_NONNULL_END

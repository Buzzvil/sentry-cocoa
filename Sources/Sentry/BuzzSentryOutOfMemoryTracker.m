#import "SentryFileManager.h"
#import <Foundation/Foundation.h>
#import <SentryAppState.h>
#import <SentryAppStateManager.h>
#import <BuzzSentryClient+Private.h>
#import <BuzzSentryDispatchQueueWrapper.h>
#import <BuzzSentryEvent.h>
#import <SentryException.h>
#import <SentryHub.h>
#import <SentryLog.h>
#import <BuzzSentryMechanism.h>
#import <BuzzSentryMessage.h>
#import <BuzzSentryOptions.h>
#import <BuzzSentryOutOfMemoryLogic.h>
#import <BuzzSentryOutOfMemoryTracker.h>
#import <BuzzSentrySDK+Private.h>

#if SENTRY_HAS_UIKIT
#    import <UIKit/UIKit.h>
#endif

@interface
BuzzSentryOutOfMemoryTracker ()

@property (nonatomic, strong) BuzzSentryOptions *options;
@property (nonatomic, strong) BuzzSentryOutOfMemoryLogic *outOfMemoryLogic;
@property (nonatomic, strong) BuzzSentryDispatchQueueWrapper *dispatchQueue;
@property (nonatomic, strong) SentryAppStateManager *appStateManager;
@property (nonatomic, strong) SentryFileManager *fileManager;

@end

@implementation BuzzSentryOutOfMemoryTracker

- (instancetype)initWithOptions:(BuzzSentryOptions *)options
               outOfMemoryLogic:(BuzzSentryOutOfMemoryLogic *)outOfMemoryLogic
                appStateManager:(SentryAppStateManager *)appStateManager
           dispatchQueueWrapper:(BuzzSentryDispatchQueueWrapper *)dispatchQueueWrapper
                    fileManager:(SentryFileManager *)fileManager
{
    if (self = [super init]) {
        self.options = options;
        self.outOfMemoryLogic = outOfMemoryLogic;
        self.appStateManager = appStateManager;
        self.dispatchQueue = dispatchQueueWrapper;
        self.fileManager = fileManager;
    }
    return self;
}

- (void)start
{
#if SENTRY_HAS_UIKIT
    [self.appStateManager start];

    [self.dispatchQueue dispatchAsyncWithBlock:^{
        if ([self.outOfMemoryLogic isOOM]) {
            BuzzSentryEvent *event = [[BuzzSentryEvent alloc] initWithLevel:kSentryLevelFatal];
            // Set to empty list so no breadcrumbs of the current scope are added
            event.breadcrumbs = @[];

            SentryException *exception =
                [[SentryException alloc] initWithValue:BuzzSentryOutOfMemoryExceptionValue
                                                  type:BuzzSentryOutOfMemoryExceptionType];
            BuzzSentryMechanism *mechanism =
                [[BuzzSentryMechanism alloc] initWithType:BuzzSentryOutOfMemoryMechanismType];
            mechanism.handled = @(NO);
            exception.mechanism = mechanism;
            event.exceptions = @[ exception ];

            // We don't need to upate the releaseName of the event to the previous app state as we
            // assume it's not an OOM when the releaseName changed between app starts.
            [SentrySDK captureCrashEvent:event];
        }
    }];
#else
    SENTRY_LOG_INFO(@"NO UIKit -> BuzzSentryOutOfMemoryTracker will not track OOM.");
    return;
#endif
}

- (void)stop
{
#if SENTRY_HAS_UIKIT
    [self.appStateManager stop];
#endif
}

@end
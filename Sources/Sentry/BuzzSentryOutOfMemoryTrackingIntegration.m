#import "SentryDefines.h"
#import <BuzzSentryAppState.h>
#import <BuzzSentryAppStateManager.h>
#import <BuzzSentryClient+Private.h>
#import <BuzzSentryCrashWrapper.h>
#import <BuzzSentryDependencyContainer.h>
#import <BuzzSentryDispatchQueueWrapper.h>
#import <BuzzSentryHub.h>
#import <BuzzSentryOptions+Private.h>
#import <BuzzSentryOutOfMemoryLogic.h>
#import <BuzzSentryOutOfMemoryTracker.h>
#import <BuzzSentryOutOfMemoryTrackingIntegration.h>
#import <BuzzSentrySDK+Private.h>

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentryOutOfMemoryTrackingIntegration ()

@property (nonatomic, strong) BuzzSentryOutOfMemoryTracker *tracker;
@property (nonatomic, strong) BuzzSentryANRTracker *anrTracker;
@property (nullable, nonatomic, copy) NSString *testConfigurationFilePath;
@property (nonatomic, strong) BuzzSentryAppStateManager *appStateManager;

@end

@implementation BuzzSentryOutOfMemoryTrackingIntegration

- (instancetype)init
{
    if (self = [super init]) {
        self.testConfigurationFilePath
            = NSProcessInfo.processInfo.environment[@"XCTestConfigurationFilePath"];
    }
    return self;
}

- (BOOL)installWithOptions:(BuzzSentryOptions *)options
{
    if (self.testConfigurationFilePath) {
        return NO;
    }

    if (![super installWithOptions:options]) {
        return NO;
    }

    dispatch_queue_attr_t attributes = dispatch_queue_attr_make_with_qos_class(
        DISPATCH_QUEUE_SERIAL, DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    BuzzSentryDispatchQueueWrapper *dispatchQueueWrapper =
        [[BuzzSentryDispatchQueueWrapper alloc] initWithName:"sentry-out-of-memory-tracker"
                                              attributes:attributes];

    BuzzSentryFileManager *fileManager = [[[BuzzSentrySDK currentHub] getClient] fileManager];
    BuzzSentryAppStateManager *appStateManager =
        [BuzzSentryDependencyContainer sharedInstance].appStateManager;
    BuzzSentryCrashWrapper *crashWrapper = [BuzzSentryDependencyContainer sharedInstance].crashWrapper;
    BuzzSentryOutOfMemoryLogic *logic =
        [[BuzzSentryOutOfMemoryLogic alloc] initWithOptions:options
                                           crashAdapter:crashWrapper
                                        appStateManager:appStateManager];

    self.tracker = [[BuzzSentryOutOfMemoryTracker alloc] initWithOptions:options
                                                    outOfMemoryLogic:logic
                                                     appStateManager:appStateManager
                                                dispatchQueueWrapper:dispatchQueueWrapper
                                                         fileManager:fileManager];
    [self.tracker start];

    self.anrTracker =
        [BuzzSentryDependencyContainer.sharedInstance getANRTracker:options.appHangTimeoutInterval];
    [self.anrTracker addListener:self];

    self.appStateManager = appStateManager;

    return YES;
}

- (BuzzSentryIntegrationOption)integrationOptions
{
    return kIntegrationOptionEnableOutOfMemoryTracking;
}

- (void)uninstall
{
    if (nil != self.tracker) {
        [self.tracker stop];
    }
    [self.anrTracker removeListener:self];
}

- (void)anrDetected
{
#if SENTRY_HAS_UIKIT
    [self.appStateManager
        updateAppState:^(BuzzSentryAppState *appState) { appState.isANROngoing = YES; }];
#endif
}

- (void)anrStopped
{
#if SENTRY_HAS_UIKIT
    [self.appStateManager
        updateAppState:^(BuzzSentryAppState *appState) { appState.isANROngoing = NO; }];
#endif
}

@end

NS_ASSUME_NONNULL_END

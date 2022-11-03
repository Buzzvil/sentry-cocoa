#import "BuzzSentryAppStartTrackingIntegration.h"
#import "BuzzSentryAppStartTracker.h"
#import "SentryDefaultCurrentDateProvider.h"
#import "SentryLog.h"
#import <Foundation/Foundation.h>
#import <PrivateBuzzSentrySDKOnly.h>
#import <SentryAppStateManager.h>
#import <SentryCrashWrapper.h>
#import <SentryDependencyContainer.h>
#import <BuzzSentryDispatchQueueWrapper.h>
#import <SentrySysctl.h>

@interface
BuzzSentryAppStartTrackingIntegration ()

#if SENTRY_HAS_UIKIT
@property (nonatomic, strong) BuzzSentryAppStartTracker *tracker;
#endif

@end

@implementation BuzzSentryAppStartTrackingIntegration

- (BOOL)installWithOptions:(BuzzSentryOptions *)options
{
#if SENTRY_HAS_UIKIT
    if (!PrivateBuzzSentrySDKOnly.appStartMeasurementHybridSDKMode
        && ![super installWithOptions:options]) {
        return NO;
    }

    SentryDefaultCurrentDateProvider *currentDateProvider =
        [SentryDefaultCurrentDateProvider sharedInstance];
    SentrySysctl *sysctl = [[SentrySysctl alloc] init];

    SentryAppStateManager *appStateManager =
        [SentryDependencyContainer sharedInstance].appStateManager;

    self.tracker = [[BuzzSentryAppStartTracker alloc]
        initWithCurrentDateProvider:currentDateProvider
               dispatchQueueWrapper:[[BuzzSentryDispatchQueueWrapper alloc] init]
                    appStateManager:appStateManager
                             sysctl:sysctl];
    [self.tracker start];

    return YES;
#else
    SENTRY_LOG_DEBUG(@"NO UIKit -> BuzzSentryAppStartTracker will not track app start up time.");
    return NO;
#endif
}

- (SentryIntegrationOption)integrationOptions
{
    return kIntegrationOptionEnableAutoPerformanceTracking | kIntegrationOptionIsTracingEnabled;
}

- (void)uninstall
{
    [self stop];
}

- (void)stop
{
#if SENTRY_HAS_UIKIT
    if (nil != self.tracker) {
        [self.tracker stop];
    }
#endif
}

@end

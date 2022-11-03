#import "SentryAppStartTrackingIntegration.h"
#import "SentryAppStartTracker.h"
#import "SentryDefaultCurrentDateProvider.h"
#import "SentryLog.h"
#import <Foundation/Foundation.h>
#import <PrivateBuzzSentrySDKOnly.h>
#import <SentryAppStateManager.h>
#import <SentryCrashWrapper.h>
#import <SentryDependencyContainer.h>
#import <SentryDispatchQueueWrapper.h>
#import <SentrySysctl.h>

@interface
SentryAppStartTrackingIntegration ()

#if SENTRY_HAS_UIKIT
@property (nonatomic, strong) SentryAppStartTracker *tracker;
#endif

@end

@implementation SentryAppStartTrackingIntegration

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

    self.tracker = [[SentryAppStartTracker alloc]
        initWithCurrentDateProvider:currentDateProvider
               dispatchQueueWrapper:[[SentryDispatchQueueWrapper alloc] init]
                    appStateManager:appStateManager
                             sysctl:sysctl];
    [self.tracker start];

    return YES;
#else
    SENTRY_LOG_DEBUG(@"NO UIKit -> SentryAppStartTracker will not track app start up time.");
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

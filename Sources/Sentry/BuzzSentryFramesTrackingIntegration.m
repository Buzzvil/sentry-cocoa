#import "BuzzSentryFramesTrackingIntegration.h"
#import "PrivateBuzzSentrySDKOnly.h"
#import "BuzzSentryFramesTracker.h"
#import "SentryLog.h"

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentryFramesTrackingIntegration ()

#if SENTRY_HAS_UIKIT
@property (nonatomic, strong) BuzzSentryFramesTracker *tracker;
#endif

@end

@implementation BuzzSentryFramesTrackingIntegration

- (BOOL)installWithOptions:(BuzzSentryOptions *)options
{
#if SENTRY_HAS_UIKIT
    if (!PrivateBuzzSentrySDKOnly.framesTrackingMeasurementHybridSDKMode
        && ![super installWithOptions:options]) {
        return NO;
    }

    self.tracker = [BuzzSentryFramesTracker sharedInstance];
    [self.tracker start];

    return YES;
#else
    [SentryLog
        logWithMessage:
            @"NO UIKit -> BuzzSentryFramesTrackingIntegration will not track slow and frozen frames."
              andLevel:kSentryLevelInfo];

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

NS_ASSUME_NONNULL_END

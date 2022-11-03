#import "BuzzSentryAutoSessionTrackingIntegration.h"
#import "BuzzSentryDefaultCurrentDateProvider.h"
#import "SentryDependencyContainer.h"
#import "BuzzSentryLog.h"
#import "BuzzSentryOptions.h"
#import "BuzzSentrySDK.h"
#import "BuzzSentrySessionTracker.h"

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentryAutoSessionTrackingIntegration ()

@property (nonatomic, strong) BuzzSentrySessionTracker *tracker;

@end

@implementation BuzzSentryAutoSessionTrackingIntegration

- (BOOL)installWithOptions:(BuzzSentryOptions *)options
{
    if (![super installWithOptions:options]) {
        return NO;
    }

    BuzzSentrySessionTracker *tracker = [[BuzzSentrySessionTracker alloc]
            initWithOptions:options
        currentDateProvider:[BuzzSentryDefaultCurrentDateProvider sharedInstance]
         notificationCenter:[SentryDependencyContainer sharedInstance].notificationCenterWrapper];
    [tracker start];
    self.tracker = tracker;

    return YES;
}

- (BuzzSentryIntegrationOption)integrationOptions
{
    return kIntegrationOptionEnableAutoSessionTracking;
}

- (void)uninstall
{
    [self stop];
}

- (void)stop
{
    if (nil != self.tracker) {
        [self.tracker stop];
    }
}

@end

NS_ASSUME_NONNULL_END

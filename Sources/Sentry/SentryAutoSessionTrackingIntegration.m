#import "SentryAutoSessionTrackingIntegration.h"
#import "SentryDefaultCurrentDateProvider.h"
#import "SentryDependencyContainer.h"
#import "SentryLog.h"
#import "BuzzSentryOptions.h"
#import "SentrySDK.h"
#import "BuzzSentrySessionTracker.h"

NS_ASSUME_NONNULL_BEGIN

@interface
SentryAutoSessionTrackingIntegration ()

@property (nonatomic, strong) BuzzSentrySessionTracker *tracker;

@end

@implementation SentryAutoSessionTrackingIntegration

- (BOOL)installWithOptions:(BuzzSentryOptions *)options
{
    if (![super installWithOptions:options]) {
        return NO;
    }

    BuzzSentrySessionTracker *tracker = [[BuzzSentrySessionTracker alloc]
            initWithOptions:options
        currentDateProvider:[SentryDefaultCurrentDateProvider sharedInstance]
         notificationCenter:[SentryDependencyContainer sharedInstance].notificationCenterWrapper];
    [tracker start];
    self.tracker = tracker;

    return YES;
}

- (SentryIntegrationOption)integrationOptions
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

#import "BuzzSentryAutoBreadcrumbTrackingIntegration.h"

NS_ASSUME_NONNULL_BEGIN

@class BuzzSentryOptions, BuzzSentryBreadcrumbTracker, BuzzSentrySystemEventBreadcrumbs;

@interface
BuzzSentryAutoBreadcrumbTrackingIntegration (Test)

- (void)installWithOptions:(nonnull BuzzSentryOptions *)options
         breadcrumbTracker:(BuzzSentryBreadcrumbTracker *)breadcrumbTracker
    systemEventBreadcrumbs:(BuzzSentrySystemEventBreadcrumbs *)systemEventBreadcrumbs;

@end

NS_ASSUME_NONNULL_END

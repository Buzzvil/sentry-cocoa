#import "SentryAutoBreadcrumbTrackingIntegration.h"

NS_ASSUME_NONNULL_BEGIN

@class BuzzSentryOptions, SentryBreadcrumbTracker, SentrySystemEventBreadcrumbs;

@interface
SentryAutoBreadcrumbTrackingIntegration (Test)

- (void)installWithOptions:(nonnull BuzzSentryOptions *)options
         breadcrumbTracker:(SentryBreadcrumbTracker *)breadcrumbTracker
    systemEventBreadcrumbs:(SentrySystemEventBreadcrumbs *)systemEventBreadcrumbs;

@end

NS_ASSUME_NONNULL_END

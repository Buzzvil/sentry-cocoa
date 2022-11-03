#import "BuzzSentryBaseIntegration.h"
#import "BuzzSentryIntegrationProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * This automatically adds breadcrumbs for different user actions.
 */
@interface BuzzSentryAutoBreadcrumbTrackingIntegration
    : BuzzSentryBaseIntegration <BuzzSentryIntegrationProtocol>

@end

NS_ASSUME_NONNULL_END

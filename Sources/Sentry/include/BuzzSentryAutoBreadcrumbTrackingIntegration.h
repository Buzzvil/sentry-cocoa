#import "SentryBaseIntegration.h"
#import "BuzzSentryIntegrationProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * This automatically adds breadcrumbs for different user actions.
 */
@interface BuzzSentryAutoBreadcrumbTrackingIntegration
    : SentryBaseIntegration <BuzzSentryIntegrationProtocol>

@end

NS_ASSUME_NONNULL_END

#import "SentryBaseIntegration.h"
#import "BuzzSentryIntegrationProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * This automatically adds breadcrumbs for different user actions.
 */
@interface SentryAutoBreadcrumbTrackingIntegration
    : SentryBaseIntegration <BuzzSentryIntegrationProtocol>

@end

NS_ASSUME_NONNULL_END

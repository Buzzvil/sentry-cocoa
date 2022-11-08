#import "BuzzSentryBaseIntegration.h"
#import "BuzzSentryIntegrationProtocol.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
#if SENTRY_HAS_UIKIT
@interface BuzzSentryUIEventTrackingIntegration : BuzzSentryBaseIntegration <BuzzSentryIntegrationProtocol>

@end
#endif
NS_ASSUME_NONNULL_END

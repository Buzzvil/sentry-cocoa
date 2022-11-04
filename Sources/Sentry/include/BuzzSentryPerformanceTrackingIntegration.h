#import "BuzzSentryBaseIntegration.h"
#import "BuzzSentryIntegrationProtocol.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Integration to setup automatic performance tracking.
 *
 * Automatic UI performance setup can be avoided by setting
 * enableAutoPerformanceTracking to NO
 * in BuzzSentryOptions during BuzzSentrySDK initialization.
 */
@interface BuzzSentryPerformanceTrackingIntegration : BuzzSentryBaseIntegration <BuzzSentryIntegrationProtocol>

@end

NS_ASSUME_NONNULL_END
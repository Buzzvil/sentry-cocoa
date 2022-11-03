#import "BuzzSentryANRTracker.h"
#import "BuzzSentryBaseIntegration.h"
#import "BuzzSentryIntegrationProtocol.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BuzzSentryOutOfMemoryTrackingIntegration
    : BuzzSentryBaseIntegration <BuzzSentryIntegrationProtocol, BuzzSentryANRTrackerDelegate>

@end

NS_ASSUME_NONNULL_END

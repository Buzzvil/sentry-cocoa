#import "BuzzSentryANRTracker.h"
#import "SentryBaseIntegration.h"
#import "BuzzSentryIntegrationProtocol.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SentryOutOfMemoryTrackingIntegration
    : SentryBaseIntegration <BuzzSentryIntegrationProtocol, BuzzSentryANRTrackerDelegate>

@end

NS_ASSUME_NONNULL_END

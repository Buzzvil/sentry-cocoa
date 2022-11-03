#import "SentryANRTracker.h"
#import "SentryBaseIntegration.h"
#import "BuzzSentryIntegrationProtocol.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SentryOutOfMemoryTrackingIntegration
    : SentryBaseIntegration <BuzzSentryIntegrationProtocol, SentryANRTrackerDelegate>

@end

NS_ASSUME_NONNULL_END

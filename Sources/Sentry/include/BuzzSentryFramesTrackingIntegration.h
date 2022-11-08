#import "BuzzSentryBaseIntegration.h"
#import "BuzzSentryIntegrationProtocol.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BuzzSentryFramesTrackingIntegration : BuzzSentryBaseIntegration <BuzzSentryIntegrationProtocol>

- (void)stop;

@end

NS_ASSUME_NONNULL_END

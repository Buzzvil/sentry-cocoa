#import "SentryBaseIntegration.h"
#import "BuzzSentryIntegrationProtocol.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BuzzSentryFramesTrackingIntegration : SentryBaseIntegration <BuzzSentryIntegrationProtocol>

- (void)stop;

@end

NS_ASSUME_NONNULL_END

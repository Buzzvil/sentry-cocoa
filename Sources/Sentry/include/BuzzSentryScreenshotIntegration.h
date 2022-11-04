#import "BuzzSentryBaseIntegration.h"
#import "BuzzSentryClient+Private.h"
#import "BuzzSentryIntegrationProtocol.h"
#import "BuzzSentryScreenshot.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
#if SENTRY_HAS_UIKIT

@interface BuzzSentryScreenshotIntegration
    : BuzzSentryBaseIntegration <BuzzSentryIntegrationProtocol, BuzzSentryClientAttachmentProcessor>

@end

#endif

NS_ASSUME_NONNULL_END
#import "SentryBaseIntegration.h"
#import "BuzzSentryClient+Private.h"
#import "SentryIntegrationProtocol.h"
#import "BuzzSentryScreenshot.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
#if SENTRY_HAS_UIKIT

@interface BuzzSentryScreenshotIntegration
    : SentryBaseIntegration <SentryIntegrationProtocol, BuzzSentryClientAttachmentProcessor>

@end

#endif

NS_ASSUME_NONNULL_END
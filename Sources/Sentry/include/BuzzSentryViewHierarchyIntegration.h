#import "SentryBaseIntegration.h"
#import "BuzzSentryClient+Private.h"
#import "BuzzSentryIntegrationProtocol.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
#if SENTRY_HAS_UIKIT

@interface BuzzSentryViewHierarchyIntegration
    : SentryBaseIntegration <BuzzSentryIntegrationProtocol, BuzzSentryClientAttachmentProcessor>

@end

#endif

NS_ASSUME_NONNULL_END

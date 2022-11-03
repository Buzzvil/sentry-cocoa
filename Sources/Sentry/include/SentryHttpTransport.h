#import "SentryDefines.h"
#import "BuzzSentryEnvelopeRateLimit.h"
#import "SentryFileManager.h"
#import "BuzzSentryRateLimits.h"
#import "SentryRequestManager.h"
#import "SentryTransport.h"
#import <Foundation/Foundation.h>

@class BuzzSentryOptions, SentryDispatchQueueWrapper, SentryNSURLRequestBuilder, SentryReachability;

NS_ASSUME_NONNULL_BEGIN

@interface SentryHttpTransport
    : NSObject <SentryTransport, BuzzSentryEnvelopeRateLimitDelegate, SentryFileManagerDelegate>
SENTRY_NO_INIT

- (id)initWithOptions:(BuzzSentryOptions *)options
             fileManager:(SentryFileManager *)fileManager
          requestManager:(id<SentryRequestManager>)requestManager
          requestBuilder:(SentryNSURLRequestBuilder *)requestBuilder
              rateLimits:(id<BuzzSentryRateLimits>)rateLimits
       envelopeRateLimit:(BuzzSentryEnvelopeRateLimit *)envelopeRateLimit
    dispatchQueueWrapper:(SentryDispatchQueueWrapper *)dispatchQueueWrapper
            reachability:(SentryReachability *)reachability;

@end

NS_ASSUME_NONNULL_END

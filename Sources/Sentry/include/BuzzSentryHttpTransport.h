#import "BuzzSentryDefines.h"
#import "BuzzSentryEnvelopeRateLimit.h"
#import "BuzzSentryFileManager.h"
#import "BuzzSentryRateLimits.h"
#import "BuzzSentryRequestManager.h"
#import "BuzzSentryTransport.h"
#import <Foundation/Foundation.h>

@class BuzzSentryOptions, BuzzSentryDispatchQueueWrapper, BuzzSentryNSURLRequestBuilder, BuzzSentryReachability;

NS_ASSUME_NONNULL_BEGIN

@interface BuzzSentryHttpTransport
    : NSObject <BuzzSentryTransport, BuzzSentryEnvelopeRateLimitDelegate, BuzzSentryFileManagerDelegate>
SENTRY_NO_INIT

- (id)initWithOptions:(BuzzSentryOptions *)options
             fileManager:(BuzzSentryFileManager *)fileManager
          requestManager:(id<BuzzSentryRequestManager>)requestManager
          requestBuilder:(BuzzSentryNSURLRequestBuilder *)requestBuilder
              rateLimits:(id<BuzzSentryRateLimits>)rateLimits
       envelopeRateLimit:(BuzzSentryEnvelopeRateLimit *)envelopeRateLimit
    dispatchQueueWrapper:(BuzzSentryDispatchQueueWrapper *)dispatchQueueWrapper
            reachability:(BuzzSentryReachability *)reachability;

@end

NS_ASSUME_NONNULL_END

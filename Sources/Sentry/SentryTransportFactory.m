#import "SentryTransportFactory.h"
#import "BuzzSentryDefaultRateLimits.h"
#import "SentryDispatchQueueWrapper.h"
#import "BuzzSentryEnvelopeRateLimit.h"
#import "SentryHttpDateParser.h"
#import "SentryHttpTransport.h"
#import "SentryNSURLRequestBuilder.h"
#import "BuzzSentryOptions.h"
#import "SentryQueueableRequestManager.h"
#import "BuzzSentryRateLimitParser.h"
#import "BuzzSentryRateLimits.h"
#import "SentryReachability.h"
#import "BuzzSentryRetryAfterHeaderParser.h"
#import "SentryTransport.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface
SentryTransportFactory ()

@end

@implementation SentryTransportFactory

+ (id<SentryTransport>)initTransport:(BuzzSentryOptions *)options
                   sentryFileManager:(SentryFileManager *)sentryFileManager
{
    NSURLSessionConfiguration *configuration =
        [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration
                                                          delegate:options.urlSessionDelegate
                                                     delegateQueue:nil];
    id<SentryRequestManager> requestManager =
        [[SentryQueueableRequestManager alloc] initWithSession:session];

    SentryHttpDateParser *httpDateParser = [[SentryHttpDateParser alloc] init];
    BuzzSentryRetryAfterHeaderParser *retryAfterHeaderParser =
        [[BuzzSentryRetryAfterHeaderParser alloc] initWithHttpDateParser:httpDateParser];
    BuzzSentryRateLimitParser *rateLimitParser = [[BuzzSentryRateLimitParser alloc] init];
    id<BuzzSentryRateLimits> rateLimits =
        [[BuzzSentryDefaultRateLimits alloc] initWithRetryAfterHeaderParser:retryAfterHeaderParser
                                                     andRateLimitParser:rateLimitParser];

    BuzzSentryEnvelopeRateLimit *envelopeRateLimit =
        [[BuzzSentryEnvelopeRateLimit alloc] initWithRateLimits:rateLimits];

    dispatch_queue_attr_t attributes = dispatch_queue_attr_make_with_qos_class(
        DISPATCH_QUEUE_SERIAL, DISPATCH_QUEUE_PRIORITY_LOW, 0);
    SentryDispatchQueueWrapper *dispatchQueueWrapper =
        [[SentryDispatchQueueWrapper alloc] initWithName:"sentry-http-transport"
                                              attributes:attributes];

    return [[SentryHttpTransport alloc] initWithOptions:options
                                            fileManager:sentryFileManager
                                         requestManager:requestManager
                                         requestBuilder:[[SentryNSURLRequestBuilder alloc] init]
                                             rateLimits:rateLimits
                                      envelopeRateLimit:envelopeRateLimit
                                   dispatchQueueWrapper:dispatchQueueWrapper
                                           reachability:[[SentryReachability alloc] init]];
}

@end

NS_ASSUME_NONNULL_END

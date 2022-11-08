#import "BuzzSentryTransportFactory.h"
#import "BuzzSentryDefaultRateLimits.h"
#import "BuzzSentryDispatchQueueWrapper.h"
#import "BuzzSentryEnvelopeRateLimit.h"
#import "BuzzSentryHttpDateParser.h"
#import "BuzzSentryHttpTransport.h"
#import "BuzzSentryNSURLRequestBuilder.h"
#import "BuzzSentryOptions.h"
#import "BuzzSentryQueueableRequestManager.h"
#import "BuzzSentryRateLimitParser.h"
#import "BuzzSentryRateLimits.h"
#import "BuzzSentryReachability.h"
#import "BuzzSentryRetryAfterHeaderParser.h"
#import "BuzzSentryTransport.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentryTransportFactory ()

@end

@implementation BuzzSentryTransportFactory

+ (id<BuzzSentryTransport>)initTransport:(BuzzSentryOptions *)options
                   BuzzSentryFileManager:(BuzzSentryFileManager *)BuzzSentryFileManager
{
    NSURLSessionConfiguration *configuration =
        [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration
                                                          delegate:options.urlSessionDelegate
                                                     delegateQueue:nil];
    id<BuzzSentryRequestManager> requestManager =
        [[BuzzSentryQueueableRequestManager alloc] initWithSession:session];

    BuzzSentryHttpDateParser *httpDateParser = [[BuzzSentryHttpDateParser alloc] init];
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
    BuzzSentryDispatchQueueWrapper *dispatchQueueWrapper =
        [[BuzzSentryDispatchQueueWrapper alloc] initWithName:"sentry-http-transport"
                                              attributes:attributes];

    return [[BuzzSentryHttpTransport alloc] initWithOptions:options
                                            fileManager:BuzzSentryFileManager
                                         requestManager:requestManager
                                         requestBuilder:[[BuzzSentryNSURLRequestBuilder alloc] init]
                                             rateLimits:rateLimits
                                      envelopeRateLimit:envelopeRateLimit
                                   dispatchQueueWrapper:dispatchQueueWrapper
                                           reachability:[[BuzzSentryReachability alloc] init]];
}

@end

NS_ASSUME_NONNULL_END

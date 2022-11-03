#import "BuzzSentryNSURLRequestBuilder.h"
#import "BuzzSentryDsn.h"
#import "BuzzSentryNSURLRequest.h"
#import "SentrySerialization.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@implementation BuzzSentryNSURLRequestBuilder

- (NSURLRequest *)createEnvelopeRequest:(BuzzSentryEnvelope *)envelope
                                    dsn:(BuzzSentryDsn *)dsn
                       didFailWithError:(NSError *_Nullable *_Nullable)error
{
    return [[BuzzSentryNSURLRequest alloc]
        initEnvelopeRequestWithDsn:dsn
                           andData:[SentrySerialization dataWithEnvelope:envelope error:error]
                  didFailWithError:error];
}

@end

NS_ASSUME_NONNULL_END
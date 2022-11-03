#import <Foundation/Foundation.h>

@class BuzzSentryEnvelope, SentryDsn;

NS_ASSUME_NONNULL_BEGIN

/**
 * A wrapper around SentryNSURLRequest for testability
 */
@interface SentryNSURLRequestBuilder : NSObject

- (NSURLRequest *)createEnvelopeRequest:(BuzzSentryEnvelope *)envelope
                                    dsn:(SentryDsn *)dsn
                       didFailWithError:(NSError *_Nullable *_Nullable)error;

@end

NS_ASSUME_NONNULL_END

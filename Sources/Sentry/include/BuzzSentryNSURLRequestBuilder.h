#import <Foundation/Foundation.h>

@class BuzzSentryEnvelope, BuzzSentryDsn;

NS_ASSUME_NONNULL_BEGIN

/**
 * A wrapper around BuzzSentryNSURLRequest for testability
 */
@interface BuzzSentryNSURLRequestBuilder : NSObject

- (NSURLRequest *)createEnvelopeRequest:(BuzzSentryEnvelope *)envelope
                                    dsn:(BuzzSentryDsn *)dsn
                       didFailWithError:(NSError *_Nullable *_Nullable)error;

@end

NS_ASSUME_NONNULL_END

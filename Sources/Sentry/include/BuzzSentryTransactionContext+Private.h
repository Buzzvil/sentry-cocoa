#import "BuzzSentryTransactionContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentryTransactionContext (Private)

- (instancetype)initWithName:(NSString *)name
                  nameSource:(BuzzSentryTransactionNameSource)source
                   operation:(NSString *)operation;

- (instancetype)initWithName:(NSString *)name
                  nameSource:(BuzzSentryTransactionNameSource)source
                   operation:(NSString *)operation
                     sampled:(BuzzSentrySampleDecision)sampled;

- (instancetype)initWithName:(NSString *)name
                  nameSource:(BuzzSentryTransactionNameSource)source
                   operation:(nonnull NSString *)operation
                     traceId:(SentryId *)traceId
                      spanId:(BuzzSentrySpanId *)spanId
                parentSpanId:(nullable BuzzSentrySpanId *)parentSpanId
               parentSampled:(BuzzSentrySampleDecision)parentSampled;

@end

NS_ASSUME_NONNULL_END

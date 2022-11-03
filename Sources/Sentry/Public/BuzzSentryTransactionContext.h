#import "BuzzSentrySampleDecision.h"
#import "BuzzSentrySpanContext.h"

NS_ASSUME_NONNULL_BEGIN

@class BuzzSentrySpanId;

NS_SWIFT_NAME(TransactionContext)
@interface BuzzSentryTransactionContext : BuzzSentrySpanContext
SENTRY_NO_INIT

/**
 * Transaction name
 */
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) BuzzSentryTransactionNameSource nameSource;

/**
 * Parent sampled
 */
@property (nonatomic) BuzzSentrySampleDecision parentSampled;

/**
 * Sample rate used for this transaction
 */
@property (nonatomic, strong, nullable) NSNumber *sampleRate;

/**
 * Init a BuzzSentryTransactionContext with given name and set other fields by default
 *
 * @param name Transaction name
 * @param operation The operation this span is measuring.
 *
 * @return BuzzSentryTransactionContext
 */
- (instancetype)initWithName:(NSString *)name operation:(NSString *)operation;

/**
 * Init a BuzzSentryTransactionContext with given name and set other fields by default
 *
 * @param name Transaction name
 * @param operation The operation this span is measuring.
 * @param sampled Determines whether the trace should be sampled.
 *
 * @return BuzzSentryTransactionContext
 */
- (instancetype)initWithName:(NSString *)name
                   operation:(NSString *)operation
                     sampled:(BuzzSentrySampleDecision)sampled;

/**
 * Init a BuzzSentryTransactionContext with given name, traceId, SpanId, parentSpanId and whether the
 * parent is sampled.
 *
 * @param name Transaction name
 * @param operation The operation this span is measuring.
 * @param traceId Trace Id
 * @param spanId Span Id
 * @param parentSpanId Parent span id
 * @param parentSampled Whether the parent is sampled
 *
 * @return BuzzSentryTransactionContext
 */
- (instancetype)initWithName:(NSString *)name
                   operation:(NSString *)operation
                     traceId:(SentryId *)traceId
                      spanId:(BuzzSentrySpanId *)spanId
                parentSpanId:(nullable BuzzSentrySpanId *)parentSpanId
               parentSampled:(BuzzSentrySampleDecision)parentSampled;

@end

NS_ASSUME_NONNULL_END

#import "BuzzSentrySpanProtocol.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BuzzSentryHub, BuzzSentryTransactionContext, BuzzSentryTraceHeader, BuzzSentryTraceContext,
    BuzzSentryDispatchQueueWrapper, BuzzSentryTracer, SentryProfilesSamplerDecision, BuzzSentryMeasurementValue;

static NSTimeInterval const BuzzSentryTracerDefaultTimeout = 3.0;

@protocol BuzzSentryTracerDelegate

/**
 * Return the active span of given tracer.
 * This function is used to determine which span will be used to create a new child.
 */
- (nullable id<BuzzSentrySpan>)activeSpanForTracer:(BuzzSentryTracer *)tracer;

@end

@interface BuzzSentryTracer : NSObject <BuzzSentrySpan>

@property (nonatomic, strong) BuzzSentryTransactionContext *transactionContext;

/**
 * The context information of the span.
 */
@property (nonatomic, readonly) BuzzSentrySpanContext *context;

/**
 * The timestamp of which the span ended.
 */
@property (nullable, nonatomic, strong) NSDate *timestamp;

/**
 * The start time of the span.
 */
@property (nullable, nonatomic, strong) NSDate *startTimestamp;

/**
 * Whether the span is finished.
 */
@property (readonly) BOOL isFinished;

@property (nullable, nonatomic, copy) void (^finishCallback)(BuzzSentryTracer *);

/**
 * Indicates whether this tracer will be finished only if all children have been finished.
 * If this property is YES and the finish function is called before all children are finished
 * the tracer will automatically finish when the last child finishes.
 */
@property (readonly) BOOL waitForChildren;

/**
 * Retrieves a trace context from this tracer.
 */
@property (nonatomic, readonly) BuzzSentryTraceContext *traceContext;

/*
 The root span of this tracer.
 */
@property (nonatomic, readonly) id<BuzzSentrySpan> rootSpan;

/*
 All the spans that where created with this tracer but rootSpan.
 */
@property (nonatomic, readonly) NSArray<id<BuzzSentrySpan>> *children;

/*
 * A delegate that provides extra information for the transaction.
 */
@property (nullable, nonatomic, weak) id<BuzzSentryTracerDelegate> delegate;

@property (nonatomic, readonly) NSDictionary<NSString *, BuzzSentryMeasurementValue *> *measurements;

/**
 * Init a BuzzSentryTracer with given transaction context and hub and set other fields by default
 *
 * @param transactionContext Transaction context
 * @param hub A hub to bind this transaction
 *
 * @return BuzzSentryTracer
 */
- (instancetype)initWithTransactionContext:(BuzzSentryTransactionContext *)transactionContext
                                       hub:(nullable BuzzSentryHub *)hub;

/**
 * Init a BuzzSentryTracer with given transaction context, hub and whether the tracer should wait
 * for all children to finish before it finishes.
 *
 * @param transactionContext Transaction context
 * @param hub A hub to bind this transaction
 * @param waitForChildren Whether this tracer should wait all children to finish.
 *
 * @return BuzzSentryTracer
 */
- (instancetype)initWithTransactionContext:(BuzzSentryTransactionContext *)transactionContext
                                       hub:(nullable BuzzSentryHub *)hub
                           waitForChildren:(BOOL)waitForChildren;

/**
 * Init a BuzzSentryTracer with given transaction context, hub and whether the tracer should wait
 * for all children to finish before it finishes.
 *
 * @param transactionContext Transaction context
 * @param hub A hub to bind this transaction
 * @param profilesSamplerDecision Whether to sample a profile corresponding to this transaction
 * @param waitForChildren Whether this tracer should wait all children to finish.
 *
 * @return BuzzSentryTracer
 */
- (instancetype)initWithTransactionContext:(BuzzSentryTransactionContext *)transactionContext
                                       hub:(nullable BuzzSentryHub *)hub
                   profilesSamplerDecision:
                       (nullable SentryProfilesSamplerDecision *)profilesSamplerDecision
                           waitForChildren:(BOOL)waitForChildren;

/**
 * Init a BuzzSentryTracer with given transaction context, hub and whether the tracer should wait
 * for all children to finish before it finishes.
 *
 * @param transactionContext Transaction context
 * @param hub A hub to bind this transaction
 * @param profilesSamplerDecision Whether to sample a profile corresponding to this transaction
 * @param idleTimeout The idle time to wait until to finish the transaction.
 *
 * @return BuzzSentryTracer
 */
- (instancetype)initWithTransactionContext:(BuzzSentryTransactionContext *)transactionContext
                                       hub:(nullable BuzzSentryHub *)hub
                   profilesSamplerDecision:
                       (nullable SentryProfilesSamplerDecision *)profilesSamplerDecision
                               idleTimeout:(NSTimeInterval)idleTimeout
                      dispatchQueueWrapper:(BuzzSentryDispatchQueueWrapper *)dispatchQueueWrapper;

- (id<BuzzSentrySpan>)startChildWithParentId:(BuzzSentrySpanId *)parentId
                               operation:(NSString *)operation
                             description:(nullable NSString *)description
    NS_SWIFT_NAME(startChild(parentId:operation:description:));

/**
 * A method to inform the tracer that a span finished.
 */
- (void)spanFinished:(id<BuzzSentrySpan>)finishedSpan;

/**
 * Get the tracer from a span.
 */
+ (nullable BuzzSentryTracer *)getTracer:(id<BuzzSentrySpan>)span;

- (void)dispatchIdleTimeout;

@end

NS_ASSUME_NONNULL_END

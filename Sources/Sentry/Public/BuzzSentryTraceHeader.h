#import "BuzzSentryDefines.h"
#import "BuzzSentrySampleDecision.h"

@class BuzzSentryId, BuzzSentrySpanId;

NS_ASSUME_NONNULL_BEGIN

static NSString *const SENTRY_TRACE_HEADER = @"sentry-trace";

NS_SWIFT_NAME(TraceHeader)
@interface BuzzSentryTraceHeader : NSObject
SENTRY_NO_INIT
/**
 * Trace ID.
 */
@property (nonatomic, readonly) BuzzSentryId *traceId;

/**
 * Span ID.
 */
@property (nonatomic, readonly) BuzzSentrySpanId *spanId;

/**
 * The trace sample decision.
 */
@property (nonatomic, readonly) BuzzSentrySampleDecision sampled;

/**
 * Initialize a BuzzSentryTraceHeader with given trace id, span id and sample decision.
 *
 * @param traceId The trace id.
 * @param spanId The span id.
 * @param sampled The decision made to sample the trace related to this header.
 *
 * @return A BuzzSentryTraceHeader.
 */
- (instancetype)initWithTraceId:(BuzzSentryId *)traceId
                         spanId:(BuzzSentrySpanId *)spanId
                        sampled:(BuzzSentrySampleDecision)sampled;

/**
 * Return the value to use in a request header.
 */
- (NSString *)value;

@end

NS_ASSUME_NONNULL_END

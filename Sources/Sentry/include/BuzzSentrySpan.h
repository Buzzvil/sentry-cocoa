#import "SentryDefines.h"
#import "BuzzSentrySerializable.h"
#import "BuzzSentrySpanContext.h"
#import "BuzzSentrySpanProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class BuzzSentryTracer;

@interface BuzzSentrySpan : NSObject <BuzzSentrySpan, BuzzSentrySerializable>
SENTRY_NO_INIT

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

/**
 * The Transaction this span is associated with.
 */
@property (nullable, nonatomic, readonly, weak) BuzzSentryTracer *tracer;

/**
 * Init a BuzzSentrySpan with given transaction and context.
 *
 * @param transaction The @c BuzzSentryTracer managing the transaction this span is associated with.
 * @param context This span context information.
 *
 * @return BuzzSentrySpan
 */
- (instancetype)initWithTracer:(BuzzSentryTracer *)transaction context:(BuzzSentrySpanContext *)context;

@end

NS_ASSUME_NONNULL_END

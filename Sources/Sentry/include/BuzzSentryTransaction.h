#import "BuzzSentryEvent.h"
#import "BuzzSentrySpanProtocol.h"
#import "BuzzSentryTracer.h"

NS_ASSUME_NONNULL_BEGIN

@class BuzzSentryTracer, BuzzSentryTransactionContext;

NS_SWIFT_NAME(Transaction)
@interface BuzzSentryTransaction : BuzzSentryEvent
SENTRY_NO_INIT

@property (nonatomic, strong) BuzzSentryTracer *trace;

- (instancetype)initWithTrace:(BuzzSentryTracer *)trace children:(NSArray<id<BuzzSentrySpan>> *)children;

@end

NS_ASSUME_NONNULL_END

#include "BuzzSentryProfilingConditionals.h"
#import "BuzzSentryTransactionContext.h"

NS_ASSUME_NONNULL_BEGIN

@class BuzzSentryThread;

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
                     traceId:(BuzzSentryId *)traceId
                      spanId:(BuzzSentrySpanId *)spanId
                parentSpanId:(nullable BuzzSentrySpanId *)parentSpanId
               parentSampled:(BuzzSentrySampleDecision)parentSampled;

#if SENTRY_TARGET_PROFILING_SUPPORTED
- (BuzzSentryThread *)sentry_threadInfo;
#endif

@end

NS_ASSUME_NONNULL_END

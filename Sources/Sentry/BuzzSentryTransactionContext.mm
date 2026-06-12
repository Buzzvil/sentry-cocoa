#import "BuzzSentryTransactionContext.h"
#include "BuzzSentryProfilingConditionals.h"
#import "BuzzSentryThread.h"
#include "BuzzSentryThreadHandle.hpp"
#import "BuzzSentryTransactionContext+Private.h"

NS_ASSUME_NONNULL_BEGIN

static const auto kSentryDefaultSamplingDecision = kBuzzSentrySampleDecisionUndecided;

@interface
BuzzSentryTransactionContext ()

#if SENTRY_TARGET_PROFILING_SUPPORTED
@property (nonatomic, strong) BuzzSentryThread *threadInfo;
#endif

@end

@implementation BuzzSentryTransactionContext

- (instancetype)initWithName:(NSString *)name operation:(NSString *)operation
{
    return [self initWithName:name
                   nameSource:kBuzzSentryTransactionNameSourceCustom
                    operation:operation];
}

- (instancetype)initWithName:(NSString *)name
                  nameSource:(BuzzSentryTransactionNameSource)source
                   operation:(NSString *)operation
{
    if (self = [super initWithOperation:operation]) {
        _name = [NSString stringWithString:name];
        _nameSource = source;
        self.parentSampled = kSentryDefaultSamplingDecision;
        [self getThreadInfo];
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name
                   operation:(NSString *)operation
                     sampled:(BuzzSentrySampleDecision)sampled
{
    return [self initWithName:name
                   nameSource:kBuzzSentryTransactionNameSourceCustom
                    operation:operation
                      sampled:sampled];
}

- (instancetype)initWithName:(NSString *)name
                  nameSource:(BuzzSentryTransactionNameSource)source
                   operation:(NSString *)operation
                     sampled:(BuzzSentrySampleDecision)sampled
{
    if (self = [super initWithOperation:operation sampled:sampled]) {
        _name = [NSString stringWithString:name];
        _nameSource = source;
        self.parentSampled = kSentryDefaultSamplingDecision;
        [self getThreadInfo];
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name
                   operation:(nonnull NSString *)operation
                     traceId:(BuzzSentryId *)traceId
                      spanId:(BuzzSentrySpanId *)spanId
                parentSpanId:(nullable BuzzSentrySpanId *)parentSpanId
               parentSampled:(BuzzSentrySampleDecision)parentSampled
{
    return [self initWithName:name
                   nameSource:kBuzzSentryTransactionNameSourceCustom
                    operation:operation
                      traceId:traceId
                       spanId:spanId
                 parentSpanId:parentSpanId
                parentSampled:parentSampled];
}

- (instancetype)initWithName:(NSString *)name
                  nameSource:(BuzzSentryTransactionNameSource)source
                   operation:(nonnull NSString *)operation
                     traceId:(BuzzSentryId *)traceId
                      spanId:(BuzzSentrySpanId *)spanId
                parentSpanId:(nullable BuzzSentrySpanId *)parentSpanId
               parentSampled:(BuzzSentrySampleDecision)parentSampled
{
    if (self = [super initWithTraceId:traceId
                               spanId:spanId
                             parentId:parentSpanId
                            operation:operation
                              sampled:kSentryDefaultSamplingDecision]) {
        _name = [NSString stringWithString:name];
        _nameSource = source;
        self.parentSampled = parentSampled;
        [self getThreadInfo];
    }
    return self;
}

- (void)getThreadInfo
{
#if SENTRY_TARGET_PROFILING_SUPPORTED
    const auto threadID = sentry::profiling::ThreadHandle::current()->tid();
    self.threadInfo = [[BuzzSentryThread alloc] initWithThreadId:@(threadID)];
#endif
}

#if SENTRY_TARGET_PROFILING_SUPPORTED
- (BuzzSentryThread *)sentry_threadInfo
{
    return self.threadInfo;
}
#endif

@end

NS_ASSUME_NONNULL_END

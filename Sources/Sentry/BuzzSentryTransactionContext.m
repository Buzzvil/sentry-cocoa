#import "BuzzSentryTransactionContext.h"

NS_ASSUME_NONNULL_BEGIN

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
        self.parentSampled = false;
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
        self.parentSampled = false;
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name
                   operation:(nonnull NSString *)operation
                     traceId:(SentryId *)traceId
                      spanId:(SentrySpanId *)spanId
                parentSpanId:(nullable SentrySpanId *)parentSpanId
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
                     traceId:(SentryId *)traceId
                      spanId:(SentrySpanId *)spanId
                parentSpanId:(nullable SentrySpanId *)parentSpanId
               parentSampled:(BuzzSentrySampleDecision)parentSampled
{
    if (self = [super initWithTraceId:traceId
                               spanId:spanId
                             parentId:parentSpanId
                            operation:operation
                              sampled:false]) {
        _name = [NSString stringWithString:name];
        _nameSource = source;
        self.parentSampled = parentSampled;
    }
    return self;
}

@end

NS_ASSUME_NONNULL_END
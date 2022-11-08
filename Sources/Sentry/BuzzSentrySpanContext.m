#import "BuzzSentrySpanContext.h"
#import "BuzzSentryId.h"
#import "BuzzSentrySpanId.h"

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentrySpanContext () {
    NSMutableDictionary<NSString *, NSString *> *_tags;
}

@end

@implementation BuzzSentrySpanContext

- (instancetype)initWithOperation:(NSString *)operation
{
    return [self initWithOperation:operation sampled:false];
}

- (instancetype)initWithOperation:(NSString *)operation sampled:(BuzzSentrySampleDecision)sampled
{
    return [self initWithTraceId:[[BuzzSentryId alloc] init]
                          spanId:[[BuzzSentrySpanId alloc] init]
                        parentId:nil
                       operation:operation
                         sampled:sampled];
}

- (instancetype)initWithTraceId:(BuzzSentryId *)traceId
                         spanId:(BuzzSentrySpanId *)spanId
                       parentId:(nullable BuzzSentrySpanId *)parentId
                      operation:(NSString *)operation
                        sampled:(BuzzSentrySampleDecision)sampled
{
    if (self = [super init]) {
        _traceId = traceId;
        _spanId = spanId;
        _parentSpanId = parentId;
        self.sampled = sampled;
        self.operation = operation;
        self.status = kBuzzSentrySpanStatusUndefined;
        _tags = [[NSMutableDictionary alloc] init];
    }
    return self;
}

+ (NSString *)type
{
    static NSString *type;
    if (type == nil)
        type = @"trace";
    return type;
}

- (NSDictionary<NSString *, NSString *> *)tags
{
    @synchronized(_tags) {
        return _tags.copy;
    }
}
- (void)setTagValue:(NSString *)value forKey:(NSString *)key
{
    @synchronized(_tags) {
        [_tags setValue:value forKey:key];
    }
}

- (void)removeTagForKey:(NSString *)key
{
    @synchronized(_tags) {
        [_tags removeObjectForKey:key];
    }
}

- (NSDictionary<NSString *, id> *)serialize
{
    NSMutableDictionary *mutabledictionary = @{
        @"type" : BuzzSentrySpanContext.type,
        @"span_id" : self.spanId.buzzSentrySpanIdString,
        @"trace_id" : self.traceId.buzzSentryIdString,
        @"op" : self.operation
    }
                                                 .mutableCopy;

    @synchronized(_tags) {
        if (_tags.count > 0) {
            mutabledictionary[@"tags"] = _tags.copy;
        }
    }

    // Since we guard for 'undecided', we'll
    // either send it if it's 'true' or 'false'.
    if (self.sampled != kBuzzSentrySampleDecisionUndecided) {
        [mutabledictionary setValue:nameForBuzzSentrySampleDecision(self.sampled) forKey:@"sampled"];
    }

    if (self.spanDescription != nil) {
        [mutabledictionary setValue:self.spanDescription forKey:@"description"];
    }

    if (self.parentSpanId != nil) {
        [mutabledictionary setValue:self.parentSpanId.buzzSentrySpanIdString forKey:@"parent_span_id"];
    }

    if (self.status != kBuzzSentrySpanStatusUndefined) {
        [mutabledictionary setValue:nameForBuzzSentrySpanStatus(self.status) forKey:@"status"];
    }

    return mutabledictionary;
}
@end

NS_ASSUME_NONNULL_END

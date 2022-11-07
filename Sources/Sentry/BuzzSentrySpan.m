#import "BuzzSentrySpan.h"
#import "NSDate+BuzzSentryExtras.h"
#import "NSDictionary+BuzzSentrySanitize.h"
#import "BuzzSentryCurrentDate.h"
#import "BuzzSentryLog.h"
#import "BuzzSentryMeasurementValue.h"
#import "BuzzSentryNoOpSpan.h"
#import "BuzzSentrySpanId.h"
#import "BuzzSentryTime.h"
#import "BuzzSentryTraceHeader.h"
#import "BuzzSentryTracer.h"

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentrySpan ()
@end

@implementation BuzzSentrySpan {
    NSMutableDictionary<NSString *, id> *_data;
    NSMutableDictionary<NSString *, id> *_tags;
    BOOL _isFinished;
}

- (instancetype)initWithTracer:(BuzzSentryTracer *)tracer context:(BuzzSentrySpanContext *)context
{
    if (self = [super init]) {
        SENTRY_LOG_DEBUG(@"Created span %@ for trace ID %@", context.spanId.BuzzSentrySpanIdString,
            tracer.context.traceId);
        _tracer = tracer;
        _context = context;
        self.startTimestamp = [BuzzSentryCurrentDate date];
        _data = [[NSMutableDictionary alloc] init];
        _tags = [[NSMutableDictionary alloc] init];
        _isFinished = NO;
    }
    return self;
}

- (id<BuzzSentrySpan>)startChildWithOperation:(NSString *)operation
{
    return [self startChildWithOperation:operation description:nil];
}

- (id<BuzzSentrySpan>)startChildWithOperation:(NSString *)operation
                              description:(nullable NSString *)description
{
    if (self.tracer == nil) {
        SENTRY_LOG_DEBUG(@"No tracer, returning no-op span");
        return [BuzzSentryNoOpSpan shared];
    }

    return [self.tracer startChildWithParentId:[self.context spanId]
                                     operation:operation
                                   description:description];
}

- (void)setDataValue:(nullable id)value forKey:(NSString *)key
{
    @synchronized(_data) {
        [_data setValue:value forKey:key];
    }
}

- (void)setExtraValue:(nullable id)value forKey:(NSString *)key
{
    [self setDataValue:value forKey:key];
}

- (void)removeDataForKey:(NSString *)key
{
    @synchronized(_data) {
        [_data removeObjectForKey:key];
    }
}

- (nullable NSDictionary<NSString *, id> *)data
{
    @synchronized(_data) {
        return [_data copy];
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

- (void)setMeasurement:(NSString *)name value:(NSNumber *)value
{
    [self.tracer setMeasurement:name value:value];
}

- (void)setMeasurement:(NSString *)name value:(NSNumber *)value unit:(BuzzSentryMeasurementUnit *)unit
{
    [self.tracer setMeasurement:name value:value unit:unit];
}

- (NSDictionary<NSString *, id> *)tags
{
    @synchronized(_tags) {
        return [_tags copy];
    }
}

- (BOOL)isFinished
{
    return _isFinished;
}

- (void)finish
{
    [self finishWithStatus:kBuzzSentrySpanStatusOk];
}

- (void)finishWithStatus:(BuzzSentrySpanStatus)status
{
    self.context.status = status;
    _isFinished = YES;
    if (self.timestamp == nil) {
        self.timestamp = [BuzzSentryCurrentDate date];
        SENTRY_LOG_DEBUG(@"Setting span timestamp: %@ at system time %llu", self.timestamp,
            (unsigned long long)getAbsoluteTime());
    }
    if (self.tracer != nil) {
        [self.tracer spanFinished:self];
    }
}

- (BuzzSentryTraceHeader *)toTraceHeader
{
    return [[BuzzSentryTraceHeader alloc] initWithTraceId:self.context.traceId
                                               spanId:self.context.spanId
                                              sampled:self.context.sampled];
}

- (NSDictionary *)serialize
{
    NSMutableDictionary<NSString *, id> *mutableDictionary =
        [[NSMutableDictionary alloc] initWithDictionary:[self.context serialize]];

    [mutableDictionary setValue:@(self.timestamp.timeIntervalSince1970) forKey:@"timestamp"];

    [mutableDictionary setValue:@(self.startTimestamp.timeIntervalSince1970)
                         forKey:@"start_timestamp"];

    @synchronized(_data) {
        if (_data.count > 0) {
            mutableDictionary[@"data"] = [_data.copy sentry_sanitize];
        }
    }

    @synchronized(_tags) {
        if (_tags.count > 0) {
            NSMutableDictionary *tags = _context.tags.mutableCopy;
            [tags addEntriesFromDictionary:_tags.copy];
            mutableDictionary[@"tags"] = tags;
        }
    }

    return mutableDictionary;
}

@end

NS_ASSUME_NONNULL_END

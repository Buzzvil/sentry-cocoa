#import "BuzzSentryNoOpSpan.h"
#import "SentryId.h"
#import "BuzzSentrySpanContext.h"
#import "BuzzSentrySpanId.h"
#import "BuzzSentryTraceHeader.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BuzzSentryNoOpSpan

+ (instancetype)shared
{
    static BuzzSentryNoOpSpan *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [[self alloc] init]; });
    return instance;
}

- (instancetype)init
{
    if (self = [super init]) {
        _context = [[BuzzSentrySpanContext alloc] initWithTraceId:SentryId.empty
                                                       spanId:BuzzSentrySpanId.empty
                                                     parentId:nil
                                                    operation:@""
                                                      sampled:kBuzzSentrySampleDecisionUndecided];
    }
    return self;
}

- (id<BuzzSentrySpan>)startChildWithOperation:(NSString *)operation
{
    return [BuzzSentryNoOpSpan shared];
}

- (id<BuzzSentrySpan>)startChildWithOperation:(NSString *)operation
                              description:(nullable NSString *)description
{
    return [BuzzSentryNoOpSpan shared];
}

- (void)setDataValue:(nullable id)value forKey:(NSString *)key
{
}

- (void)setExtraValue:(nullable id)value forKey:(NSString *)key
{
}

- (void)removeDataForKey:(NSString *)key
{
}

- (nullable NSDictionary<NSString *, id> *)data
{
    return nil;
}

- (void)setTagValue:(NSString *)value forKey:(NSString *)key
{
}

- (void)removeTagForKey:(NSString *)key
{
}

- (void)setMeasurement:(NSString *)name value:(NSNumber *)value
{
}

- (void)setMeasurement:(NSString *)name value:(NSNumber *)value unit:(SentryMeasurementUnit *)unit
{
}

- (NSDictionary<NSString *, id> *)tags
{
    return @{};
}

- (BOOL)isFinished
{
    return NO;
}

- (void)finish
{
}

- (void)finishWithStatus:(BuzzSentrySpanStatus)status
{
}

- (BuzzSentryTraceHeader *)toTraceHeader
{
    return [[BuzzSentryTraceHeader alloc] initWithTraceId:self.context.traceId
                                               spanId:self.context.spanId
                                              sampled:self.context.sampled];
}

- (NSDictionary *)serialize
{
    return @{};
}

@end

NS_ASSUME_NONNULL_END

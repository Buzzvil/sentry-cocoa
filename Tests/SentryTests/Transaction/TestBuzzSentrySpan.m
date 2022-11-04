#import "TestBuzzSentrySpan.h"
#import "BuzzSentrySpanProtocol.h"
#import "BuzzSentryTracer.h"

@implementation TestBuzzSentrySpan

@synthesize context;
@synthesize data;
@synthesize isFinished;
@synthesize tags;
@synthesize startTimestamp;
@synthesize timestamp;

- (id<BuzzSentrySpan>)startChildWithOperation:(NSString *)operation description:(NSString *)description
{
    return nil;
}

- (id<BuzzSentrySpan>)startChildWithOperation:(nonnull NSString *)operation
{
    return nil;
}

- (BuzzSentryTraceHeader *)toTraceHeader
{
    return nil;
}

- (NSDictionary<NSString *, id> *)serialize
{
    return nil;
}

- (void)finish
{
}

- (void)finishWithStatus:(BuzzSentrySpanStatus)status
{
}

- (void)removeDataForKey:(nonnull NSString *)key
{
}

- (void)removeTagForKey:(nonnull NSString *)key
{
}

- (void)setDataValue:(nullable id)value forKey:(nonnull NSString *)key
{
}

- (void)setExtraValue:(nullable id)value forKey:(nonnull NSString *)key
{
}

- (void)setTagValue:(nonnull NSString *)value forKey:(nonnull NSString *)key
{
}

- (void)setMeasurement:(nonnull NSString *)name value:(nonnull NSNumber *)value
{
}

- (void)setMeasurement:(NSString *)name value:(NSNumber *)value unit:(BuzzSentryMeasurementUnit *)unit
{
}

@end
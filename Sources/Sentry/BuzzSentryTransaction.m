#import "BuzzSentryTransaction.h"
#import "NSDictionary+SentrySanitize.h"
#import "SentryEnvelopeItemType.h"
#import "BuzzSentryMeasurementValue.h"
#import "BuzzSentryTransactionContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentryTransaction ()

@property (nonatomic, strong) NSArray<id<BuzzSentrySpan>> *spans;

@end

@implementation BuzzSentryTransaction

- (instancetype)initWithTrace:(BuzzSentryTracer *)trace children:(NSArray<id<BuzzSentrySpan>> *)children
{
    if (self = [super init]) {
        self.timestamp = trace.timestamp;
        self.startTimestamp = trace.startTimestamp;
        self.trace = trace;
        self.spans = children;
        self.type = SentryEnvelopeItemTypeTransaction;
    }
    return self;
}

- (NSDictionary<NSString *, id> *)serialize
{
    NSMutableDictionary<NSString *, id> *serializedData =
        [[NSMutableDictionary alloc] initWithDictionary:[super serialize]];

    NSMutableArray *serializedSpans = [[NSMutableArray alloc] init];
    for (id<BuzzSentrySpan> span in self.spans) {
        [serializedSpans addObject:[span serialize]];
    }
    serializedData[@"spans"] = serializedSpans;

    NSMutableDictionary<NSString *, id> *mutableContext = [[NSMutableDictionary alloc] init];
    if (serializedData[@"contexts"] != nil) {
        [mutableContext addEntriesFromDictionary:serializedData[@"contexts"]];
    }

    mutableContext[@"trace"] = [self.trace serialize];
    [serializedData setValue:mutableContext forKey:@"contexts"];

    NSMutableDictionary<NSString *, id> *traceTags =
        [[self.trace.tags sentry_sanitize] mutableCopy];
    [traceTags addEntriesFromDictionary:[self.trace.context.tags sentry_sanitize]];

    // Adding tags from Trace to serializedData dictionary
    if (serializedData[@"tags"] != nil &&
        [serializedData[@"tags"] isKindOfClass:NSDictionary.class]) {
        NSMutableDictionary *tags = [NSMutableDictionary new];
        [tags addEntriesFromDictionary:serializedData[@"tags"]];
        [tags addEntriesFromDictionary:traceTags];
        serializedData[@"tags"] = tags;
    } else {
        serializedData[@"tags"] = traceTags;
    }

    NSDictionary<NSString *, id> *traceData = [self.trace.data sentry_sanitize];

    // Adding data from Trace to serializedData dictionary
    if (serializedData[@"extra"] != nil &&
        [serializedData[@"extra"] isKindOfClass:NSDictionary.class]) {
        NSMutableDictionary *extra = [NSMutableDictionary new];
        [extra addEntriesFromDictionary:serializedData[@"extra"]];
        [extra addEntriesFromDictionary:traceData];
        serializedData[@"extra"] = extra;
    } else {
        serializedData[@"extra"] = traceData;
    }

    if (self.trace.measurements.count > 0) {
        NSMutableDictionary<NSString *, id> *measurements = [NSMutableDictionary dictionary];

        for (NSString *measurementName in self.trace.measurements.allKeys) {
            measurements[measurementName] = [self.trace.measurements[measurementName] serialize];
        }

        serializedData[@"measurements"] = measurements;
    }

    if (self.trace) {
        [serializedData setValue:self.trace.transactionContext.name forKey:@"transaction"];

        serializedData[@"transaction_info"] =
            @{ @"source" : [self stringForNameSource:self.trace.transactionContext.nameSource] };
    }

    return serializedData;
}

- (NSString *)stringForNameSource:(BuzzSentryTransactionNameSource)source
{
    switch (source) {
    case kBuzzSentryTransactionNameSourceCustom:
        return @"custom";
    case kBuzzSentryTransactionNameSourceUrl:
        return @"url";
    case kBuzzSentryTransactionNameSourceRoute:
        return @"route";
    case kBuzzSentryTransactionNameSourceView:
        return @"view";
    case kBuzzSentryTransactionNameSourceComponent:
        return @"component";
    case kBuzzSentryTransactionNameSourceTask:
        return @"task";
    }
}
@end

NS_ASSUME_NONNULL_END

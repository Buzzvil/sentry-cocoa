#import "BuzzSentryTraceHeader.h"
#import "SentryId.h"
#import "BuzzSentrySpanId.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BuzzSentryTraceHeader

@synthesize traceId = _traceId;
@synthesize spanId = _spanId;
@synthesize sampled = _sampled;

- (instancetype)initWithTraceId:(SentryId *)traceId
                         spanId:(BuzzSentrySpanId *)spanId
                        sampled:(BuzzSentrySampleDecision)sampleDecision
{
    if (self = [super init]) {
        _traceId = traceId;
        _spanId = spanId;
        _sampled = sampleDecision;
    }
    return self;
}

- (NSString *)value
{
    return _sampled != kBuzzSentrySampleDecisionUndecided
        ? [NSString stringWithFormat:@"%@-%@-%i", _traceId.sentryIdString,
                    _spanId.BuzzSentrySpanIdString, _sampled == kBuzzSentrySampleDecisionYes ? 1 : 0]
        : [NSString stringWithFormat:@"%@-%@", _traceId.sentryIdString, _spanId.BuzzSentrySpanIdString];
}

@end

NS_ASSUME_NONNULL_END

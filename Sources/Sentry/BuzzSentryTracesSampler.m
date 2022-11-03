#import "BuzzSentryTracesSampler.h"
#import "SentryDependencyContainer.h"
#import "BuzzSentryOptions.h"
#import "BuzzSentrySamplingContext.h"
#import "BuzzSentryTransactionContext.h"
#import <BuzzSentryOptions+Private.h>

NS_ASSUME_NONNULL_BEGIN

@implementation BuzzSentryTracesSamplerDecision

- (instancetype)initWithDecision:(BuzzSentrySampleDecision)decision
                   forSampleRate:(nullable NSNumber *)sampleRate
{
    if (self = [super init]) {
        _decision = decision;
        _sampleRate = sampleRate;
    }
    return self;
}

@end

@implementation BuzzSentryTracesSampler {
    BuzzSentryOptions *_options;
}

- (instancetype)initWithOptions:(BuzzSentryOptions *)options random:(id<BuzzSentryRandom>)random
{
    if (self = [super init]) {
        _options = options;
        self.random = random;
    }
    return self;
}

- (instancetype)initWithOptions:(BuzzSentryOptions *)options
{
    return [self initWithOptions:options random:[SentryDependencyContainer sharedInstance].random];
}

- (BuzzSentryTracesSamplerDecision *)sample:(BuzzSentrySamplingContext *)context
{
    if (context.transactionContext.sampled != kBuzzSentrySampleDecisionUndecided) {
        return [[BuzzSentryTracesSamplerDecision alloc]
            initWithDecision:context.transactionContext.sampled
               forSampleRate:context.transactionContext.sampleRate];
    }

    if (_options.tracesSampler != nil) {
        NSNumber *callbackDecision = _options.tracesSampler(context);
        if (callbackDecision != nil) {
            if (![_options isValidTracesSampleRate:callbackDecision]) {
                callbackDecision = _options.defaultTracesSampleRate;
            }
        }
        if (callbackDecision != nil) {
            return [self calcSample:callbackDecision.doubleValue];
        }
    }

    if (context.transactionContext.parentSampled != kBuzzSentrySampleDecisionUndecided)
        return [[BuzzSentryTracesSamplerDecision alloc]
            initWithDecision:context.transactionContext.parentSampled
               forSampleRate:context.transactionContext.sampleRate];

    if (_options.tracesSampleRate != nil)
        return [self calcSample:_options.tracesSampleRate.doubleValue];

    return [[BuzzSentryTracesSamplerDecision alloc] initWithDecision:kBuzzSentrySampleDecisionNo
                                                   forSampleRate:nil];
}

- (BuzzSentryTracesSamplerDecision *)calcSample:(double)rate
{
    double r = [self.random nextNumber];
    BuzzSentrySampleDecision decision = r <= rate ? kBuzzSentrySampleDecisionYes : kBuzzSentrySampleDecisionNo;
    return [[BuzzSentryTracesSamplerDecision alloc] initWithDecision:decision
                                                   forSampleRate:[NSNumber numberWithDouble:rate]];
}

@end

NS_ASSUME_NONNULL_END

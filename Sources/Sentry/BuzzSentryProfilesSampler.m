#import "BuzzSentryProfilesSampler.h"
#import "BuzzSentryDependencyContainer.h"
#import "BuzzSentryOptions+Private.h"
#import "BuzzSentryTracesSampler.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BuzzSentryProfilesSamplerDecision

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

@implementation BuzzSentryProfilesSampler {
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
    return [self initWithOptions:options random:[BuzzSentryDependencyContainer sharedInstance].random];
}

- (BuzzSentryProfilesSamplerDecision *)sample:(BuzzSentrySamplingContext *)context
                    tracesSamplerDecision:(BuzzSentryTracesSamplerDecision *)tracesSamplerDecision
{
    // Profiles are always undersampled with respect to traces. If the trace is not sampled,
    // the profile will not be either. If the trace is sampled, we can proceed to checking
    // whether the associated profile should be sampled.
#if SENTRY_TARGET_PROFILING_SUPPORTED
    if (tracesSamplerDecision.decision == kBuzzSentrySampleDecisionYes) {
        if (_options.profilesSampler != nil) {
            NSNumber *callbackDecision = _options.profilesSampler(context);
            if (callbackDecision != nil) {
                if (![_options isValidProfilesSampleRate:callbackDecision]) {
                    callbackDecision = _options.defaultProfilesSampleRate;
                }
            }
            if (callbackDecision != nil) {
                return [self calcSample:callbackDecision.doubleValue];
            }
        }

        if (_options.profilesSampleRate != nil) {
            return [self calcSample:_options.profilesSampleRate.doubleValue];
        }

        // Backward compatibility for clients that are still using the enableProfiling option.
#    pragma clang diagnostic push
#    pragma clang diagnostic ignored "-Wdeprecated-declarations"
        if (_options.enableProfiling) {
            return [[BuzzSentryProfilesSamplerDecision alloc] initWithDecision:kBuzzSentrySampleDecisionYes
                                                             forSampleRate:@1.0];
        }
#    pragma clang diagnostic pop
    }
#endif

    return [[BuzzSentryProfilesSamplerDecision alloc] initWithDecision:kBuzzSentrySampleDecisionNo
                                                     forSampleRate:nil];
}

- (BuzzSentryProfilesSamplerDecision *)calcSample:(double)rate
{
    double r = [self.random nextNumber];
    BuzzSentrySampleDecision decision = r <= rate ? kBuzzSentrySampleDecisionYes : kBuzzSentrySampleDecisionNo;
    return
        [[BuzzSentryProfilesSamplerDecision alloc] initWithDecision:decision
                                                  forSampleRate:[NSNumber numberWithDouble:rate]];
}

@end

NS_ASSUME_NONNULL_END

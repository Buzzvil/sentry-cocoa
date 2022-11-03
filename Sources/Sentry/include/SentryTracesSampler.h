#import "BuzzSentryRandom.h"
#import "SentrySampleDecision.h"

NS_ASSUME_NONNULL_BEGIN

@class BuzzSentryOptions, SentrySamplingContext;

@interface SentryTracesSamplerDecision : NSObject

@property (nonatomic, readonly) SentrySampleDecision decision;

@property (nullable, nonatomic, strong, readonly) NSNumber *sampleRate;

- (instancetype)initWithDecision:(SentrySampleDecision)decision
                   forSampleRate:(nullable NSNumber *)sampleRate;

@end

@interface SentryTracesSampler : NSObject

/**
 *  A random number generator
 */
@property (nonatomic, strong) id<BuzzSentryRandom> random;

/**
 * Init a TracesSampler with given options and random generator.
 * @param options Sentry options with sampling configuration
 * @param random A random number generator
 */
- (instancetype)initWithOptions:(BuzzSentryOptions *)options random:(id<BuzzSentryRandom>)random;

/**
 * Init a TracesSampler with given options and a default Random generator.
 * @param options Sentry options with sampling configuration
 */
- (instancetype)initWithOptions:(BuzzSentryOptions *)options;

/**
 * Determines whether a trace should be sampled based on the context and options.
 */
- (SentryTracesSamplerDecision *)sample:(SentrySamplingContext *)context;

@end

NS_ASSUME_NONNULL_END

#import "BuzzSentryRandom.h"
#import "BuzzSentrySampleDecision.h"

NS_ASSUME_NONNULL_BEGIN

@class BuzzSentryOptions, BuzzSentrySamplingContext;

@interface BuzzSentryTracesSamplerDecision : NSObject

@property (nonatomic, readonly) BuzzSentrySampleDecision decision;

@property (nullable, nonatomic, strong, readonly) NSNumber *sampleRate;

- (instancetype)initWithDecision:(BuzzSentrySampleDecision)decision
                   forSampleRate:(nullable NSNumber *)sampleRate;

@end

@interface BuzzSentryTracesSampler : NSObject

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
- (BuzzSentryTracesSamplerDecision *)sample:(BuzzSentrySamplingContext *)context;

@end

NS_ASSUME_NONNULL_END
#import "BuzzSentryRandom.h"
#import "BuzzSentrySampleDecision.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BuzzSentryOptions, BuzzSentrySamplingContext, BuzzSentryTracesSamplerDecision;

@interface SentryProfilesSamplerDecision : NSObject

@property (nonatomic, readonly) BuzzSentrySampleDecision decision;

@property (nullable, nonatomic, strong, readonly) NSNumber *sampleRate;

- (instancetype)initWithDecision:(BuzzSentrySampleDecision)decision
                   forSampleRate:(nullable NSNumber *)sampleRate;

@end

@interface SentryProfilesSampler : NSObject

/**
 *  A random number generator
 */
@property (nonatomic, strong) id<BuzzSentryRandom> random;

/**
 * Init a ProfilesSampler with given options and random generator.
 * @param options Sentry options with sampling configuration
 * @param random A random number generator
 */
- (instancetype)initWithOptions:(BuzzSentryOptions *)options random:(id<BuzzSentryRandom>)random;

/**
 * Init a ProfilesSampler with given options and a default Random generator.
 * @param options Sentry options with sampling configuration
 */
- (instancetype)initWithOptions:(BuzzSentryOptions *)options;

/**
 * Determines whether a profile should be sampled based on the context, options, and
 * whether the trace corresponding to the profile was sampled.
 */
- (SentryProfilesSamplerDecision *)sample:(BuzzSentrySamplingContext *)context
                    tracesSamplerDecision:(BuzzSentryTracesSamplerDecision *)tracesSamplerDecision;

@end

NS_ASSUME_NONNULL_END

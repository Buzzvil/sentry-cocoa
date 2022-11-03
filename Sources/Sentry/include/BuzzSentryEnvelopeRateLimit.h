#import "BuzzSentryRateLimits.h"
#import <Foundation/Foundation.h>

@protocol BuzzSentryEnvelopeRateLimitDelegate;

@class BuzzSentryEnvelope;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(EnvelopeRateLimit)
@interface BuzzSentryEnvelopeRateLimit : NSObject

- (instancetype)initWithRateLimits:(id<BuzzSentryRateLimits>)sentryRateLimits;

/**
 * Removes SentryEnvelopItems for which a rate limit is active.
 */
- (BuzzSentryEnvelope *)removeRateLimitedItems:(BuzzSentryEnvelope *)envelope;

- (void)setDelegate:(id<BuzzSentryEnvelopeRateLimitDelegate>)delegate;

@end

@protocol BuzzSentryEnvelopeRateLimitDelegate <NSObject>

- (void)envelopeItemDropped:(SentryDataCategory)dataCategory;

@end

NS_ASSUME_NONNULL_END

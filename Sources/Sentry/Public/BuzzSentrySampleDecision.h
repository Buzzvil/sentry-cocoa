#import <Foundation/Foundation.h>

/**
 * Trace sample decision flag.
 */
typedef NS_ENUM(NSUInteger, BuzzSentrySampleDecision) {
    /**
     * Used when the decision to sample a trace should be postponed.
     */
    kBuzzSentrySampleDecisionUndecided,

    /**
     * The trace should be sampled.
     */
    kBuzzSentrySampleDecisionYes,

    /**
     * The trace should not be sampled.
     */
    kBuzzSentrySampleDecisionNo
};

static DEPRECATED_MSG_ATTRIBUTE("Use nameForBuzzSentrySampleDecision() instead.")
    NSString *_Nonnull const BuzzSentrySampleDecisionNames[]
    = { @"undecided", @"true", @"false" };

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const kBuzzSentrySampleDecisionNameUndecided;
FOUNDATION_EXPORT NSString *const kBuzzSentrySampleDecisionNameYes;
FOUNDATION_EXPORT NSString *const kBuzzSentrySampleDecisionNameNo;

NSString *nameForBuzzSentrySampleDecision(BuzzSentrySampleDecision decision);

NS_ASSUME_NONNULL_END

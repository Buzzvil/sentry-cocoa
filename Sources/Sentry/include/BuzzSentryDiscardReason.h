#import <Foundation/Foundation.h>

/**
 * A reason that defines why events were lost, see
 * https://develop.sentry.dev/sdk/client-reports/#envelope-item-payload.
 */
typedef NS_ENUM(NSUInteger, BuzzSentryDiscardReason) {
    kBuzzSentryDiscardReasonBeforeSend = 0,
    kBuzzSentryDiscardReasonEventProcessor = 1,
    kBuzzSentryDiscardReasonSampleRate = 2,
    kBuzzSentryDiscardReasonNetworkError = 3,
    kBuzzSentryDiscardReasonQueueOverflow = 4,
    kBuzzSentryDiscardReasonCacheOverflow = 5,
    kBuzzSentryDiscardReasonRateLimitBackoff = 6
};

static DEPRECATED_MSG_ATTRIBUTE(
    "Use nameForBuzzSentryDiscardReason() instead.") NSString *_Nonnull const BuzzSentryDiscardReasonNames[]
    = { @"before_send", @"event_processor", @"sample_rate", @"network_error", @"queue_overflow",
          @"cache_overflow", @"ratelimit_backoff" };

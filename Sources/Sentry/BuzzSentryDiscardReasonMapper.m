#import "BuzzSentryDiscardReasonMapper.h"

NSString *const kBuzzSentryDiscardReasonNameBeforeSend = @"before_send";
NSString *const kBuzzSentryDiscardReasonNameEventProcessor = @"event_processor";
NSString *const kBuzzSentryDiscardReasonNameSampleRate = @"sample_rate";
NSString *const kBuzzSentryDiscardReasonNameNetworkError = @"network_error";
NSString *const kBuzzSentryDiscardReasonNameQueueOverflow = @"queue_overflow";
NSString *const kBuzzSentryDiscardReasonNameCacheOverflow = @"cache_overflow";
NSString *const kBuzzSentryDiscardReasonNameRateLimitBackoff = @"ratelimit_backoff";

NSString *_Nonnull nameForBuzzSentryDiscardReason(BuzzSentryDiscardReason reason)
{
    switch (reason) {
    case kBuzzSentryDiscardReasonBeforeSend:
        return kBuzzSentryDiscardReasonNameBeforeSend;
    case kBuzzSentryDiscardReasonEventProcessor:
        return kBuzzSentryDiscardReasonNameEventProcessor;
    case kBuzzSentryDiscardReasonSampleRate:
        return kBuzzSentryDiscardReasonNameSampleRate;
    case kBuzzSentryDiscardReasonNetworkError:
        return kBuzzSentryDiscardReasonNameNetworkError;
    case kBuzzSentryDiscardReasonQueueOverflow:
        return kBuzzSentryDiscardReasonNameQueueOverflow;
    case kBuzzSentryDiscardReasonCacheOverflow:
        return kBuzzSentryDiscardReasonNameCacheOverflow;
    case kBuzzSentryDiscardReasonRateLimitBackoff:
        return kBuzzSentryDiscardReasonNameRateLimitBackoff;
    }
}

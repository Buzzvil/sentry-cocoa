#import "BuzzSentryDataCategory.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** A thread safe wrapper around a dictionary to store rate limits.
 */
@interface BuzzSentryConcurrentRateLimitsDictionary : NSObject

/**
 Adds the passed rate limit for the given category. If a rate limit already
 exists it is overwritten.
 */
- (void)addRateLimit:(BuzzSentryDataCategory)category validUntil:(NSDate *)date;

/** Returns the date until the rate limit is active. */
- (NSDate *)getRateLimitForCategory:(BuzzSentryDataCategory)category;

@end

NS_ASSUME_NONNULL_END

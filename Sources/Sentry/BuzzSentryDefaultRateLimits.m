#import "BuzzSentryDefaultRateLimits.h"
#import "BuzzSentryConcurrentRateLimitsDictionary.h"
#import "BuzzSentryCurrentDate.h"
#import "BuzzSentryDataCategoryMapper.h"
#import "BuzzSentryDateUtil.h"
#import "BuzzSentryLog.h"
#import "BuzzSentryRateLimitParser.h"
#import "BuzzSentryRetryAfterHeaderParser.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentryDefaultRateLimits ()

@property (nonatomic, strong) BuzzSentryConcurrentRateLimitsDictionary *rateLimits;
@property (nonatomic, strong) BuzzSentryRetryAfterHeaderParser *retryAfterHeaderParser;
@property (nonatomic, strong) BuzzSentryRateLimitParser *rateLimitParser;

@end

@implementation BuzzSentryDefaultRateLimits

- (instancetype)initWithRetryAfterHeaderParser:
                    (BuzzSentryRetryAfterHeaderParser *)retryAfterHeaderParser
                            andRateLimitParser:(BuzzSentryRateLimitParser *)rateLimitParser
{
    if (self = [super init]) {
        self.rateLimits = [[BuzzSentryConcurrentRateLimitsDictionary alloc] init];
        self.retryAfterHeaderParser = retryAfterHeaderParser;
        self.rateLimitParser = rateLimitParser;
    }
    return self;
}

- (BOOL)isRateLimitActive:(BuzzSentryDataCategory)category
{
    NSDate *categoryDate = [self.rateLimits getRateLimitForCategory:category];
    NSDate *allCategoriesDate = [self.rateLimits getRateLimitForCategory:kBuzzSentryDataCategoryAll];

    BOOL isActiveForCategory = [BuzzSentryDateUtil isInFuture:categoryDate];
    BOOL isActiveForCategories = [BuzzSentryDateUtil isInFuture:allCategoriesDate];

    if (isActiveForCategory || isActiveForCategories) {
        return YES;
    } else {
        return NO;
    }
}

- (void)update:(NSHTTPURLResponse *)response
{
    NSString *rateLimitsHeader = response.allHeaderFields[@"X-Sentry-Rate-Limits"];
    if (nil != rateLimitsHeader) {
        NSDictionary<NSNumber *, NSDate *> *limits = [self.rateLimitParser parse:rateLimitsHeader];

        for (NSNumber *categoryAsNumber in limits.allKeys) {
            BuzzSentryDataCategory category
                = BuzzSentryDataCategoryForNSUInteger(categoryAsNumber.unsignedIntegerValue);

            [self updateRateLimit:category withDate:limits[categoryAsNumber]];
        }
    } else if (response.statusCode == 429) {
        NSDate *retryAfterHeaderDate =
            [self.retryAfterHeaderParser parse:response.allHeaderFields[@"Retry-After"]];

        if (nil == retryAfterHeaderDate) {
            // parsing failed use default value
            retryAfterHeaderDate = [[BuzzSentryCurrentDate date] dateByAddingTimeInterval:60];
        }

        [self updateRateLimit:kBuzzSentryDataCategoryAll withDate:retryAfterHeaderDate];
    }
}

- (void)updateRateLimit:(BuzzSentryDataCategory)category withDate:(NSDate *)newDate
{
    NSDate *existingDate = [self.rateLimits getRateLimitForCategory:category];
    NSDate *longerRateLimitDate = [BuzzSentryDateUtil getMaximumDate:existingDate andOther:newDate];
    [self.rateLimits addRateLimit:category validUntil:longerRateLimitDate];
}

@end

NS_ASSUME_NONNULL_END

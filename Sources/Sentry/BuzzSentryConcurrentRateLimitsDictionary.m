#import "BuzzSentryConcurrentRateLimitsDictionary.h"
#import <Foundation/Foundation.h>

@interface
BuzzSentryConcurrentRateLimitsDictionary ()

/* Key is the type and value is valid until date */
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSDate *> *rateLimits;

@end

@implementation BuzzSentryConcurrentRateLimitsDictionary

- (instancetype)init
{
    if (self = [super init]) {
        self.rateLimits = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)addRateLimit:(BuzzSentryDataCategory)category validUntil:(NSDate *)date
{
    @synchronized(self.rateLimits) {
        self.rateLimits[@(category)] = date;
    }
}

- (NSDate *)getRateLimitForCategory:(BuzzSentryDataCategory)category
{
    @synchronized(self.rateLimits) {
        return self.rateLimits[@(category)];
    }
}

@end
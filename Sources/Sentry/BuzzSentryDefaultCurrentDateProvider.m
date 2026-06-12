#import "BuzzSentryDefaultCurrentDateProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentryDefaultCurrentDateProvider ()

@end

@implementation BuzzSentryDefaultCurrentDateProvider

+ (instancetype)sharedInstance
{
    static BuzzSentryDefaultCurrentDateProvider *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [[self alloc] init]; });
    return instance;
}

- (NSDate *_Nonnull)date
{
    return [NSDate date];
}

- (dispatch_time_t)dispatchTimeNow
{
    return dispatch_time(DISPATCH_TIME_NOW, 0);
}

- (NSInteger)timezoneOffset
{
    return [NSTimeZone localTimeZone].secondsFromGMT;
}

@end

NS_ASSUME_NONNULL_END

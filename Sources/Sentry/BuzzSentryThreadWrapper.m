#import "BuzzSentryThreadWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BuzzSentryThreadWrapper

- (void)sleepForTimeInterval:(NSTimeInterval)timeInterval
{
    [NSThread sleepForTimeInterval:timeInterval];
}

@end

NS_ASSUME_NONNULL_END

#import "BuzzSentryCurrentDate.h"
#import "BuzzSentryCurrentDateProvider.h"
#import "BuzzSentryDefaultCurrentDateProvider.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentryCurrentDate ()

@end

@implementation BuzzSentryCurrentDate

static id<BuzzSentryCurrentDateProvider> currentDateProvider;

+ (NSDate *)date
{
    if (nil == currentDateProvider) {
        currentDateProvider = [BuzzSentryDefaultCurrentDateProvider sharedInstance];
    }
    return [currentDateProvider date];
}

+ (dispatch_time_t)dispatchTimeNow
{
    if (nil == currentDateProvider) {
        currentDateProvider = [BuzzSentryDefaultCurrentDateProvider sharedInstance];
    }
    return [currentDateProvider dispatchTimeNow];
}

+ (void)setCurrentDateProvider:(nullable id<BuzzSentryCurrentDateProvider>)value
{
    currentDateProvider = value;
}

+ (nullable id<BuzzSentryCurrentDateProvider>)getCurrentDateProvider
{
    return currentDateProvider;
}

@end

NS_ASSUME_NONNULL_END

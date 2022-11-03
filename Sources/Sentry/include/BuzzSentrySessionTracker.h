#import "SentryCurrentDateProvider.h"
#import "SentryDefines.h"
#import <Foundation/Foundation.h>

@class BuzzSentryEvent, BuzzSentryOptions, SentryCurrentDateProvider, SentryNSNotificationCenterWrapper;

/**
 * Tracks sessions for release health. For more info see:
 * https://docs.sentry.io/workflow/releases/health/#session
 */
NS_SWIFT_NAME(SessionTracker)
@interface BuzzSentrySessionTracker : NSObject
SENTRY_NO_INIT

- (instancetype)initWithOptions:(BuzzSentryOptions *)options
            currentDateProvider:(id<SentryCurrentDateProvider>)currentDateProvider
             notificationCenter:(SentryNSNotificationCenterWrapper *)notificationCenter;

- (void)start;
- (void)stop;
@end
#import "SentryCrashDynamicLinker.h"
#import "SentryCrashStackCursor.h"
#import "SentryDefines.h"
#import <Foundation/Foundation.h>

@class BuzzSentryFrame, SentryInAppLogic;

NS_ASSUME_NONNULL_BEGIN

@interface SentryCrashStackEntryMapper : NSObject
SENTRY_NO_INIT

- (instancetype)initWithInAppLogic:(SentryInAppLogic *)inAppLogic;

/**
 * Maps the stackEntry of a SentryCrashStackCursor to BuzzSentryFrame.
 *
 * @param stackCursor An with SentryCrash initialized stackCursor. You can use for example
 * sentrycrashsc_initSelfThread.
 */
- (BuzzSentryFrame *)mapStackEntryWithCursor:(SentryCrashStackCursor)stackCursor;

/**
 * Maps a SentryCrashStackEntry to BuzzSentryFrame.
 *
 * @param stackEntry A stack entry retrieved from a thread.
 */
- (BuzzSentryFrame *)sentryCrashStackEntryToBuzzSentryFrame:(SentryCrashStackEntry)stackEntry;

@end

NS_ASSUME_NONNULL_END

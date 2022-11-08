#import "BuzzSentryCrashDynamicLinker.h"
#import "BuzzSentryCrashStackCursor.h"
#import "BuzzSentryDefines.h"
#import <Foundation/Foundation.h>

@class BuzzSentryFrame, BuzzSentryInAppLogic;

NS_ASSUME_NONNULL_BEGIN

@interface BuzzSentryCrashStackEntryMapper : NSObject
SENTRY_NO_INIT

- (instancetype)initWithInAppLogic:(BuzzSentryInAppLogic *)inAppLogic;

/**
 * Maps the stackEntry of a BuzzSentryCrashStackCursor to BuzzSentryFrame.
 *
 * @param stackCursor An with BuzzSentryCrash initialized stackCursor. You can use for example
 * sentrycrashsc_initSelfThread.
 */
- (BuzzSentryFrame *)mapStackEntryWithCursor:(BuzzSentryCrashStackCursor)stackCursor;

/**
 * Maps a BuzzSentryCrashStackEntry to BuzzSentryFrame.
 *
 * @param stackEntry A stack entry retrieved from a thread.
 */
- (BuzzSentryFrame *)sentryCrashStackEntryToBuzzSentryFrame:(BuzzSentryCrashStackEntry)stackEntry;

@end

NS_ASSUME_NONNULL_END

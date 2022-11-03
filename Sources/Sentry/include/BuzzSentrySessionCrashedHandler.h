#import <Foundation/Foundation.h>

@class SentryCrashWrapper, BuzzSentryDispatchQueueWrapper, BuzzSentryOutOfMemoryLogic;

@interface BuzzSentrySessionCrashedHandler : NSObject

- (instancetype)initWithCrashWrapper:(SentryCrashWrapper *)crashWrapper
                    outOfMemoryLogic:(BuzzSentryOutOfMemoryLogic *)outOfMemoryLogic;

/**
 * When a crash happened the current session is ended as crashed, stored at a different
 * location and the current session is deleted. Checkout BuzzSentryHub where most of the session logic
 * is implemented for more details about sessions.
 */
- (void)endCurrentSessionAsCrashedWhenCrashOrOOM;

@end

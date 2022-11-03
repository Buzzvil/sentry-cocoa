#import "SentryDefines.h"
#import "BuzzSentryObjCRuntimeWrapper.h"

/**
 * A wrapper around the objc runtime functions for testability.
 */
@interface BuzzSentryDefaultObjCRuntimeWrapper : NSObject <BuzzSentryObjCRuntimeWrapper>
SENTRY_NO_INIT

+ (instancetype)sharedInstance;

@end

#import "BuzzSentryCurrentDateProvider.h"
#import "BuzzSentryDefines.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(DefaultCurrentDateProvider)
@interface BuzzSentryDefaultCurrentDateProvider : NSObject <BuzzSentryCurrentDateProvider>
SENTRY_NO_INIT

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END

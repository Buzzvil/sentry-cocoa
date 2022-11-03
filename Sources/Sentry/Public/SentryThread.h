#import "BuzzSentryDefines.h"
#import "BuzzSentrySerializable.h"

NS_ASSUME_NONNULL_BEGIN

@class BuzzSentryStacktrace;

NS_SWIFT_NAME(Thread)
@interface SentryThread : NSObject <BuzzSentrySerializable>
SENTRY_NO_INIT

/**
 * Number of the thread
 */
@property (nonatomic, copy) NSNumber *threadId;

/**
 * Name (if available) of the thread
 */
@property (nonatomic, copy) NSString *_Nullable name;

/**
 * BuzzSentryStacktrace of the SentryThread
 */
@property (nonatomic, strong) BuzzSentryStacktrace *_Nullable stacktrace;

/**
 * Did this thread crash?
 */
@property (nonatomic, copy) NSNumber *_Nullable crashed;

/**
 * Was it the current thread.
 */
@property (nonatomic, copy) NSNumber *_Nullable current;

/**
 * Initializes a SentryThread with its id
 * @param threadId NSNumber
 * @return SentryThread
 */
- (instancetype)initWithThreadId:(NSNumber *)threadId;

@end

NS_ASSUME_NONNULL_END

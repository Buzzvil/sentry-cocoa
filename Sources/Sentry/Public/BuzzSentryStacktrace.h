#import <Foundation/Foundation.h>

#import <BuzzSentry/BuzzSentryDefines.h>
#import <BuzzSentry/BuzzSentrySerializable.h>

NS_ASSUME_NONNULL_BEGIN

@class BuzzSentryFrame;

NS_SWIFT_NAME(Stacktrace)
@interface BuzzSentryStacktrace : NSObject <BuzzSentrySerializable>
SENTRY_NO_INIT

/**
 * Array of all BuzzSentryFrame in the stacktrace
 */
@property (nonatomic, strong) NSArray<BuzzSentryFrame *> *frames;

/**
 * Registers of the thread for additional information used on the server
 */
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *registers;

/**
 * Initialize a BuzzSentryStacktrace with frames and registers
 * @param frames NSArray
 * @param registers NSArray
 * @return BuzzSentryStacktrace
 */
- (instancetype)initWithFrames:(NSArray<BuzzSentryFrame *> *)frames
                     registers:(NSDictionary<NSString *, NSString *> *)registers;

/**
 * This will be called internally, is used to remove duplicated frames for
 * certain crashes.
 */
- (void)fixDuplicateFrames;

@end

NS_ASSUME_NONNULL_END

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A wrapper around NSThread functions for testability.
 */
@interface BuzzSentryThreadWrapper : NSObject

- (void)sleepForTimeInterval:(NSTimeInterval)timeInterval;

@end

NS_ASSUME_NONNULL_END

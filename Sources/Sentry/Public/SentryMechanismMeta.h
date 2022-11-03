#import "SentryDefines.h"
#import "BuzzSentrySerializable.h"
#import <Foundation/Foundation.h>

@class BuzzSentryNSError;

NS_ASSUME_NONNULL_BEGIN

/**
 * The mechanism metadata usually carries error codes reported by the runtime or operating system,
 * along with a platform-dependent interpretation of these codes.
 *
 * See https://develop.sentry.dev/sdk/event-payloads/exception/#meta-information.
 */
NS_SWIFT_NAME(MechanismMeta)
@interface SentryMechanismMeta : NSObject <BuzzSentrySerializable>

- (instancetype)init;

/**
 * Information on the POSIX signal. On Apple systems, signals also carry a code in addition to the
 * signal number describing the signal in more detail. On Linux, this code does not exist.
 */
@property (nullable, nonatomic, strong) NSDictionary<NSString *, id> *signal;

/**
 * A Mach Exception on Apple systems comprising a code triple and optional descriptions.
 */
@property (nullable, nonatomic, strong) NSDictionary<NSString *, id> *machException;

/**
 * Sentry uses the NSErrors domain and code for grouping. Only domain and code are serialized.
 */
@property (nullable, nonatomic, strong) BuzzSentryNSError *error;

@end

NS_ASSUME_NONNULL_END

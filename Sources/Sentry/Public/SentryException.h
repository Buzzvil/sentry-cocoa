#import <Foundation/Foundation.h>

#import "BuzzSentryDefines.h"
#import "BuzzSentrySerializable.h"

NS_ASSUME_NONNULL_BEGIN

@class BuzzSentryStacktrace, BuzzSentryMechanism;

NS_SWIFT_NAME(Exception)
@interface SentryException : NSObject <BuzzSentrySerializable>
SENTRY_NO_INIT

/**
 * The name of the exception
 */
@property (nonatomic, copy) NSString *value;

/**
 * Type of the exception
 */
@property (nonatomic, copy) NSString *type;

/**
 * Additional information about the exception
 */
@property (nonatomic, strong) BuzzSentryMechanism *_Nullable mechanism;

/**
 * Can be set to define the module
 */
@property (nonatomic, copy) NSString *_Nullable module;

/**
 * An optional value which refers to a thread in `BuzzSentryEvent.threads`.
 */
@property (nonatomic, copy) NSNumber *_Nullable threadId;

/**
 * Stacktrace containing frames of this exception.
 */
@property (nonatomic, strong) BuzzSentryStacktrace *_Nullable stacktrace;

/**
 * Initialize an SentryException with value and type
 * @param value String
 * @param type String
 * @return SentryException
 */
- (instancetype)initWithValue:(NSString *)value type:(NSString *)type;

@end

NS_ASSUME_NONNULL_END

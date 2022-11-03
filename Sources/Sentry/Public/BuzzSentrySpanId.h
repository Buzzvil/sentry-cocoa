#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A 16 character Id.
 */

NS_SWIFT_NAME(SpanId)
@interface BuzzSentrySpanId : NSObject <NSCopying>

/**
 * Creates a BuzzSentrySpanId with a random 16 character Id.
 */
- (instancetype)init;

/**
 * Creates a BuzzSentrySpanId with the first 16 characters of the given UUID.
 */
- (instancetype)initWithUUID:(NSUUID *)uuid;

/**
 * Creates a BuzzSentrySpanId from a 16 character string.
 * Returns a empty BuzzSentrySpanId with the input is invalid.
 */
- (instancetype)initWithValue:(NSString *)value;

/**
 * Returns the Span Id Value
 */
@property (readonly, copy) NSString *BuzzSentrySpanIdString;

/**
 * A BuzzSentrySpanId with an empty Id "0000000000000000".
 */
@property (class, nonatomic, readonly, strong) BuzzSentrySpanId *empty;

@end

NS_ASSUME_NONNULL_END

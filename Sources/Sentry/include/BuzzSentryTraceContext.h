#import "BuzzSentryId.h"
#import "BuzzSentrySerializable.h"

NS_ASSUME_NONNULL_BEGIN

@class BuzzSentryScope, BuzzSentryOptions, BuzzSentryTracer, BuzzSentryUser, BuzzSentryBaggage;

@interface BuzzSentryTraceContext : NSObject <BuzzSentrySerializable>

/**
 * UUID V4 encoded as a hexadecimal sequence with no dashes (e.g. 771a43a4192642f0b136d5159a501700)
 * that is a sequence of 32 hexadecimal digits.
 */
@property (nonatomic, readonly) BuzzSentryId *traceId;

/**
 * Public key from the DSN used by the SDK.
 */
@property (nonatomic, readonly) NSString *publicKey;

/**
 * The release name as specified in client options, usually: package@x.y.z+build.
 */
@property (nullable, nonatomic, readonly) NSString *releaseName;

/**
 * The environment name as specified in client options, for example staging.
 */
@property (nullable, nonatomic, readonly) NSString *environment;

/**
 * The transaction name set on the scope.
 */
@property (nullable, nonatomic, readonly) NSString *transaction;

/**
 * A subset of the scope's user context.
 */
@property (nullable, nonatomic, readonly) NSString *userSegment;

/**
 * Sample rate used for this trace.
 */
@property (nullable, nonatomic) NSString *sampleRate;

/**
 * Initializes a BuzzSentryTraceContext with given properties.
 */
- (instancetype)initWithTraceId:(BuzzSentryId *)traceId
                      publicKey:(NSString *)publicKey
                    releaseName:(nullable NSString *)releaseName
                    environment:(nullable NSString *)environment
                    transaction:(nullable NSString *)transaction
                    userSegment:(nullable NSString *)userSegment
                     sampleRate:(nullable NSString *)sampleRate;

/**
 * Initializes a BuzzSentryTraceContext with data from scope and options.
 */
- (nullable instancetype)initWithScope:(BuzzSentryScope *)scope options:(BuzzSentryOptions *)options;

/**
 * Initializes a BuzzSentryTraceContext with data from a dictionary.
 */
- (nullable instancetype)initWithDict:(NSDictionary<NSString *, id> *)dictionary;

/**
 * Initializes a BuzzSentryTraceContext with data from a trace, scope and options.
 */
- (nullable instancetype)initWithTracer:(BuzzSentryTracer *)tracer
                                  scope:(nullable BuzzSentryScope *)scope
                                options:(BuzzSentryOptions *)options;

/**
 * Create a BuzzSentryBaggage with the information of this BuzzSentryTraceContext.
 */
- (BuzzSentryBaggage *)toBaggage;
@end

NS_ASSUME_NONNULL_END
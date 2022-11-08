#import "BuzzSentrySDK.h"

@class BuzzSentryHub, BuzzSentryId, BuzzSentryAppStartMeasurement, BuzzSentryEnvelope;

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentrySDK (Private)

+ (void)captureCrashEvent:(BuzzSentryEvent *)event;

+ (void)captureCrashEvent:(BuzzSentryEvent *)event withScope:(BuzzSentryScope *)scope;

/**
 * SDK private field to store the state if onCrashedLastRun was called.
 */
@property (nonatomic, class) BOOL crashedLastRunCalled;

+ (void)setAppStartMeasurement:(nullable BuzzSentryAppStartMeasurement *)appStartMeasurement;

+ (nullable BuzzSentryAppStartMeasurement *)getAppStartMeasurement;

@property (nonatomic, class) NSUInteger startInvocations;

+ (BuzzSentryHub *)currentHub;

@property (nonatomic, nullable, readonly, class) BuzzSentryOptions *options;

/**
 * Needed by hybrid SDKs as react-native to synchronously store an envelope to disk.
 */
+ (void)storeEnvelope:(BuzzSentryEnvelope *)envelope;

/**
 * Needed by hybrid SDKs as react-native to synchronously capture an envelope.
 */
+ (void)captureEnvelope:(BuzzSentryEnvelope *)envelope;

/**
 * Start a transaction with a name and a name source.
 */
+ (id<BuzzSentrySpan>)startTransactionWithName:(NSString *)name
                                nameSource:(BuzzSentryTransactionNameSource)source
                                 operation:(NSString *)operation;

+ (id<BuzzSentrySpan>)startTransactionWithName:(NSString *)name
                                nameSource:(BuzzSentryTransactionNameSource)source
                                 operation:(NSString *)operation
                               bindToScope:(BOOL)bindToScope;

@end

NS_ASSUME_NONNULL_END

#import "BuzzSentryHub.h"

@class BuzzSentryEnvelopeItem, BuzzSentryId, BuzzSentryScope, BuzzSentryTransaction, BuzzSentryDispatchQueueWrapper,
    BuzzSentryTracer;

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentryHub (Private)

@property (nonatomic, strong)
    NSMutableArray<NSObject<BuzzSentryIntegrationProtocol> *> *installedIntegrations;
@property (nonatomic, strong) NSMutableArray<NSString *> *installedIntegrationNames;

- (BuzzSentryClient *_Nullable)client;

- (void)captureCrashEvent:(BuzzSentryEvent *)event;

- (void)captureCrashEvent:(BuzzSentryEvent *)event withScope:(BuzzSentryScope *)scope;

- (void)setSampleRandomValue:(NSNumber *)value;

- (void)closeCachedSessionWithTimestamp:(NSDate *_Nullable)timestamp;

- (id<BuzzSentrySpan>)startTransactionWithName:(NSString *)name
                                nameSource:(BuzzSentryTransactionNameSource)source
                                 operation:(NSString *)operation;

- (id<BuzzSentrySpan>)startTransactionWithName:(NSString *)name
                                nameSource:(BuzzSentryTransactionNameSource)source
                                 operation:(NSString *)operation
                               bindToScope:(BOOL)bindToScope;

- (id<BuzzSentrySpan>)startTransactionWithContext:(BuzzSentryTransactionContext *)transactionContext
                                  bindToScope:(BOOL)bindToScope
                              waitForChildren:(BOOL)waitForChildren
                        customSamplingContext:(NSDictionary<NSString *, id> *)customSamplingContext;

- (BuzzSentryTracer *)startTransactionWithContext:(BuzzSentryTransactionContext *)transactionContext
                                  bindToScope:(BOOL)bindToScope
                        customSamplingContext:(NSDictionary<NSString *, id> *)customSamplingContext
                                  idleTimeout:(NSTimeInterval)idleTimeout
                         dispatchQueueWrapper:(BuzzSentryDispatchQueueWrapper *)dispatchQueueWrapper;

- (BuzzSentryId *)captureEvent:(BuzzSentryEvent *)event
                  withScope:(BuzzSentryScope *)scope
    additionalEnvelopeItems:(NSArray<BuzzSentryEnvelopeItem *> *)additionalEnvelopeItems
    NS_SWIFT_NAME(capture(event:scope:additionalEnvelopeItems:));

- (BuzzSentryId *)captureTransaction:(BuzzSentryTransaction *)transaction withScope:(BuzzSentryScope *)scope;

- (BuzzSentryId *)captureTransaction:(BuzzSentryTransaction *)transaction
                       withScope:(BuzzSentryScope *)scope
         additionalEnvelopeItems:(NSArray<BuzzSentryEnvelopeItem *> *)additionalEnvelopeItems;

@end

NS_ASSUME_NONNULL_END

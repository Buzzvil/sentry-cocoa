#import "BuzzSentrySamplingContext.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BuzzSentrySamplingContext

- (instancetype)initWithTransactionContext:(BuzzSentryTransactionContext *)transactionContext
{
    if (self = [super init]) {
        _transactionContext = transactionContext;
    }
    return self;
}

- (instancetype)initWithTransactionContext:(BuzzSentryTransactionContext *)transactionContext
                     customSamplingContext:(NSDictionary<NSString *, id> *)customSamplingContext
{
    self = [self initWithTransactionContext:transactionContext];
    _customSamplingContext = customSamplingContext;
    return self;
}

@end

NS_ASSUME_NONNULL_END

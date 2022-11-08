#import "BuzzSentryDataCategory.h"
#import "BuzzSentryDiscardReason.h"
#import <Foundation/Foundation.h>

@class BuzzSentryEnvelope;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Transport)
@protocol BuzzSentryTransport <NSObject>

- (void)sendEnvelope:(BuzzSentryEnvelope *)envelope NS_SWIFT_NAME(send(envelope:));

- (void)recordLostEvent:(BuzzSentryDataCategory)category reason:(BuzzSentryDiscardReason)reason;

- (BOOL)flush:(NSTimeInterval)timeout;

@end

NS_ASSUME_NONNULL_END

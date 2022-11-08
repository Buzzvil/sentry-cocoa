#import "BuzzSentryEnvelope.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentryEnvelopeItem (Private)

- (instancetype)initWithClientReport:(BuzzSentryClientReport *)clientReport;

@end

NS_ASSUME_NONNULL_END

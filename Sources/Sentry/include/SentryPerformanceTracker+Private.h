#import "SentryPerformanceTracker.h"

@interface
SentryPerformanceTracker (Private)

- (SentrySpanId *)startSpanWithName:(NSString *)name
                         nameSource:(BuzzSentryTransactionNameSource)source
                          operation:(NSString *)operation;

- (void)measureSpanWithDescription:(NSString *)description
                        nameSource:(BuzzSentryTransactionNameSource)source
                         operation:(NSString *)operation
                           inBlock:(void (^)(void))block;

- (void)measureSpanWithDescription:(NSString *)description
                        nameSource:(BuzzSentryTransactionNameSource)source
                         operation:(NSString *)operation
                      parentSpanId:(SentrySpanId *)parentSpanId
                           inBlock:(void (^)(void))block;

@end

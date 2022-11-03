#import "BuzzSentryPerformanceTracker.h"

@interface
BuzzSentryPerformanceTracker (Private)

- (BuzzSentrySpanId *)startSpanWithName:(NSString *)name
                         nameSource:(BuzzSentryTransactionNameSource)source
                          operation:(NSString *)operation;

- (void)measureSpanWithDescription:(NSString *)description
                        nameSource:(BuzzSentryTransactionNameSource)source
                         operation:(NSString *)operation
                           inBlock:(void (^)(void))block;

- (void)measureSpanWithDescription:(NSString *)description
                        nameSource:(BuzzSentryTransactionNameSource)source
                         operation:(NSString *)operation
                      parentSpanId:(BuzzSentrySpanId *)parentSpanId
                           inBlock:(void (^)(void))block;

@end

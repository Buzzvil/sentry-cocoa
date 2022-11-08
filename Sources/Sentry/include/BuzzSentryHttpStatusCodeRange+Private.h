#import "BuzzSentryDefines.h"
#import "BuzzSentryHttpStatusCodeRange.h"

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentryHttpStatusCodeRange (Private)

- (BOOL)isInRange:(NSInteger)statusCode;

@end

NS_ASSUME_NONNULL_END

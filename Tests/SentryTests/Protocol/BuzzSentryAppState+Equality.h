#import "BuzzSentryAppState.h"

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentryAppState (Equality)

- (BOOL)isEqual:(id _Nullable)object;

- (NSUInteger)hash;

@end

NS_ASSUME_NONNULL_END
#import "BuzzSentrySession.h"

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentrySession (Equality)

- (BOOL)isEqual:(id _Nullable)object;

- (BOOL)isEqualToSession:(BuzzSentrySession *)session;

- (NSUInteger)hash;

@end

NS_ASSUME_NONNULL_END

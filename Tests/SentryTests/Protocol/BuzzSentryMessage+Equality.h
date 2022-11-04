#import "BuzzSentryMessage.h"

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentryMessage (Equality)

- (BOOL)isEqual:(id _Nullable)object;

- (BOOL)isEqualToMessage:(BuzzSentryMessage *)message;

- (NSUInteger)hash;

@end

NS_ASSUME_NONNULL_END

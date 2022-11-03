#import "BuzzSentryScope+Properties.h"
#import <BuzzSentry/BuzzSentry.h>

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentryScope (Equality)

- (BOOL)isEqual:(id _Nullable)other;
- (BOOL)isEqualToScope:(BuzzSentryScope *)scope;
- (NSUInteger)hash;

@end

NS_ASSUME_NONNULL_END

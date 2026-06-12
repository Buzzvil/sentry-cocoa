#import <BuzzSentry/BuzzSentry.h>

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentryAttachment (Equality)

- (BOOL)isEqual:(id _Nullable)other;

- (BOOL)isEqualToAttachment:(BuzzSentryAttachment *)attachment;

- (NSUInteger)hash;

@end

NS_ASSUME_NONNULL_END

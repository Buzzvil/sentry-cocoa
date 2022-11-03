#import "SentryDefines.h"

#if SENTRY_HAS_UIKIT

NS_ASSUME_NONNULL_BEGIN

@interface BuzzSentryViewHierarchy : NSObject

- (NSArray<NSString *> *)fetchViewHierarchy;

- (void)saveViewHierarchy:(NSString *)path;
@end

NS_ASSUME_NONNULL_END
#endif

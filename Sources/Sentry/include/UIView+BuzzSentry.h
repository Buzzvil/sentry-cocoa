#import "BuzzSentryDefines.h"

#if SENTRY_HAS_UIKIT
#    import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface
UIView (BuzzSentry)

- (NSString *)sentry_recursiveViewHierarchyDescription;

@end

NS_ASSUME_NONNULL_END

#endif
